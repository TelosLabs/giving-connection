module SpreadsheetImport
  module Hours
    # Extracts an open/close pair from the time portion of an hours cell.
    #
    # #call returns a ["09:00", "17:00"] pair of local wall-clock strings, or a
    # symbol saying why there is no pair: :closed, :appointment, :all_day or
    # :unparsed. Guessing is deliberately limited — a range we cannot read
    # unambiguously comes back as :unparsed so the caller can report it, rather
    # than being rounded into plausible-looking hours.
    class TimeSpec
      HOUR = /\d{1,2}(?::\d{2})?\s*(?:[ap]\.?m\.?)?/i
      RANGE = /(#{HOUR})\s*-\s*(#{HOUR})/i
      MERIDIEM = /[ap]\.?m\.?/i
      BARE_HOUR = /\A\d{1,2}\z/
      CLOSED = /\bclosed?\b/i
      APPOINTMENT = /\bappointment\b/i
      ALL_DAY = /24\s*\/\s*7|\b24\s*h(?:ou)?rs?\b|\ball\s*day\b|\bopen\s*24\b/i

      # The opening hours a bare "9-5" can only sensibly mean, and the closing
      # hours that have to be afternoon for the range to make sense.
      MORNING_OPEN = (6..12)
      AFTERNOON_CLOSE = (1..5)

      def initialize(input)
        @input = input.to_s
      end

      def call
        return :all_day if ALL_DAY.match?(cleaned)

        match = RANGE.match(cleaned)
        return marker if match.nil? || qualified_before?(match)

        range_from(match)
      end

      # True when the cell lists a second range we have nowhere to put, e.g. a
      # split shift written "8-12, 1-5".
      def extra_range?
        match = RANGE.match(cleaned)
        return false if match.nil?

        RANGE.match?(cleaned[match.end(0)..])
      end

      private

      # Parenthesised asides ("(closed holidays)") describe exceptions, not the
      # weekly schedule, so they must not be read as either times or markers.
      def cleaned
        @cleaned ||= @input.gsub(/\([^)]*\)/, " ")
          .gsub(/(\d{1,2})\.(\d{2})\b/, '\1:\2')
          .gsub(/\s+/, " ")
          .strip
      end

      # "by appointment 9-5" is an appointment, not a nine-to-five: a marker
      # standing in front of the range qualifies it away. One trailing the range
      # ("9-5, holidays closed") is an aside and is ignored.
      def qualified_before?(match)
        head = cleaned[0...match.begin(0)]
        CLOSED.match?(head) || APPOINTMENT.match?(head)
      end

      def marker
        return :closed if CLOSED.match?(cleaned)
        return :appointment if APPOINTMENT.match?(cleaned)

        :unparsed
      end

      def range_from(match)
        open_raw, close_raw = match.captures.map(&:strip)
        open_time = parse(open_raw)
        close_time = parse(close_raw)
        return :unparsed unless open_time && close_time

        infer(open_raw, close_raw, open_time, close_time)
      end

      def parse(token)
        return nil if impossible_hour?(token)

        token = "#{token}:00" if token.match?(BARE_HOUR)
        Time.zone.parse(token)&.strftime("%H:%M")
      rescue ArgumentError
        nil
      end

      # "13pm" is a typo, not one o'clock in the afternoon.
      def impossible_hour?(token)
        token.match?(MERIDIEM) && token[/\d{1,2}/].to_i > 12
      end

      def infer(open_raw, close_raw, open_time, close_time)
        return [open_time, bump(close_time)] if afternoon_close?(close_raw, open_time, close_time)
        return :unparsed if close_time <= open_time
        return :unparsed if bare?(open_raw) && bare?(close_raw) && hour_of(open_time) < 6

        [open_time, close_time]
      end

      # "9-5", "12-1" and "9am-5" all close in the afternoon. A closing hour
      # that already carries am/pm is taken at its word, and an opening hour
      # outside the morning gives us nothing to anchor the guess on.
      def afternoon_close?(close_raw, open_time, close_time)
        return false if close_raw.match?(MERIDIEM)

        MORNING_OPEN.cover?(hour_of(open_time)) && AFTERNOON_CLOSE.cover?(hour_of(close_time))
      end

      def bump(close_time)
        hour, minute = close_time.split(":")
        format("%02d:%s", hour.to_i + 12, minute)
      end

      def hour_of(time)
        time[0, 2].to_i
      end

      def bare?(token)
        token.match?(BARE_HOUR)
      end
    end
  end
end
