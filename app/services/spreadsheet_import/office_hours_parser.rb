module SpreadsheetImport
  class OfficeHoursParser
    DAYS = %w[sunday monday tuesday wednesday thursday friday saturday]

    # Every spelling/abbreviation we accept for a single day, mapped to its
    # canonical name. Spreadsheet cells use a wild mix of these ("Mon", "Tues",
    # "Thurs", "Weds", bare initials) so we normalize aggressively rather than
    # crash on anything unexpected.
    DAY_ALIASES = {
      "sunday" => "sunday", "sun" => "sunday", "su" => "sunday", "u" => "sunday",
      "monday" => "monday", "mon" => "monday", "mo" => "monday", "m" => "monday",
      "tuesday" => "tuesday", "tues" => "tuesday", "tue" => "tuesday", "tu" => "tuesday",
      "wednesday" => "wednesday", "weds" => "wednesday", "wed" => "wednesday", "we" => "wednesday", "w" => "wednesday",
      "thursday" => "thursday", "thurs" => "thursday", "thur" => "thursday", "thu" => "thursday", "thr" => "thursday", "th" => "thursday", "r" => "thursday",
      "friday" => "friday", "fri" => "friday", "fr" => "friday", "f" => "friday",
      "saturday" => "saturday", "sat" => "saturday", "sa" => "saturday"
    }.freeze

    # Keyword groups that expand to a set of days on their own (no explicit
    # range needed): "Weekdays 9-5", "Daily 8:00 - 20:00", etc.
    DAY_GROUPS = {
      "weekday" => %w[monday tuesday wednesday thursday friday],
      "weekdays" => %w[monday tuesday wednesday thursday friday],
      "businessdays" => %w[monday tuesday wednesday thursday friday],
      "weekend" => %w[saturday sunday],
      "weekends" => %w[saturday sunday],
      "daily" => DAYS,
      "everyday" => DAYS,
      "allweek" => DAYS,
      "7days" => DAYS,
      "7daysaweek" => DAYS
    }.freeze

    # Whole cells that mean "no weekly schedule to parse".
    BLANK_VALUES = ["", "na", "n/a", "none", "tbd", "-", "--"].freeze

    def initialize(input)
      @input = input.to_s
    end

    def call
      return [] if blank_input?

      parts = split_into_entries(@input)

      parsed_entries = parts.flat_map { |part| parse_single_part(part) }

      full_week = normalize_to_full_week(parsed_entries)

      normalize_days_to_indexes(full_week)
    end

    private

    # Fold the many ways a cell expresses a range/separator into a single canonical
    # form: unicode dashes and the words "to"/"through"/"thru" all become "-", and
    # whitespace is collapsed. Done before any splitting so downstream logic only
    # ever sees one delimiter.
    def normalize(str)
      str.gsub(/[–—]/, "-")
        .gsub(/\b(?:to|through|thru|til|till|until)\b/i, "-")
        .gsub(/\s+/, " ")
        .strip
    end

    def parse_days(day_str)
      cleaned = day_str.to_s.downcase.gsub(/[:\-]+$/, "").strip

      group = DAY_GROUPS[cleaned.delete(".").gsub(/\s+/, "")]
      return group.dup if group

      # Days can be listed with commas, slashes ("Mon/Wed/Fri") or "&".
      parts = cleaned.split(/[,\/&]/).map(&:strip).compact_blank

      parts.flat_map do |part|
        if part.include?("-")
          start_day, end_day = part.split("-", 2).map { |d| standardize_day(d) }
          days_between(start_day, end_day)
        else
          Array(standardize_day(part))
        end
      end.compact
    end

    def extract_times(time_str)
      normalized = time_str.to_s.strip.downcase
      return [nil, nil] if normalized.blank?
      return [nil, nil] if normalized.include?("closed") || normalized.include?("appointment")

      open_raw, close_raw = time_str.strip.split(/[\-–]/, 2).map(&:strip)
      open_time = normalize_time(open_raw)
      close_time = normalize_time(close_raw)

      # "9-5" almost always means 9am-5pm. When both endpoints are bare hours
      # (no am/pm, no minutes) and the closing hour lands at or before the
      # opening hour, bump the close into the afternoon.
      if bare_hour?(open_raw) && bare_hour?(close_raw) && open_time && close_time
        open_hour = open_time[0, 2].to_i
        close_hour = close_time[0, 2].to_i
        close_time = format("%02d:00", close_hour + 12) if close_hour <= open_hour && close_hour < 12
      end

      [open_time, close_time]
    end

    def bare_hour?(token)
      token.to_s.strip.match?(/\A\d{1,2}\z/)
    end

    def days_between(start_day, end_day)
      return [] unless start_day && end_day
      start_index = DAYS.index(start_day)
      end_index = DAYS.index(end_day)
      return [] unless start_index && end_index
      if start_index <= end_index
        DAYS[start_index..end_index]
      else
        DAYS[start_index..] + DAYS[0..end_index]
      end
    end

    # Pull the first recognizable day out of a token/phrase. Scanning word-by-word
    # (rather than matching the whole string) lets us tolerate noise like a
    # "Hours:" prefix or stray punctuation around the actual day name.
    def standardize_day(str)
      str.to_s.downcase.delete(".").scan(/[a-z]+/).each do |token|
        day = DAY_ALIASES[token]
        return day if day
      end
      nil
    end

    def normalize_time(time)
      return nil if time.blank?
      cleaned = time.strip
      # A bare hour ("9", "18") won't parse on its own (Time.zone.parse("9")
      # is nil and "12" is read as a day-of-month), so give it explicit minutes.
      cleaned = "#{cleaned}:00" if bare_hour?(cleaned)
      begin
        # Return the local wall-clock time as written. OfficeHour converts to
        # UTC on save (see TimeZoneConvertible), so shifting here would double
        # the conversion.
        Time.zone.parse(cleaned).strftime("%H:%M")
      rescue
        nil
      end
    end

    def blank_input?
      BLANK_VALUES.include?(@input.strip.downcase)
    end

    # Entries may be separated by "&" or by line breaks — spreadsheet cells with
    # multiple day ranges frequently put each range on its own line. Split on
    # both before normalizing so a newline can't collapse two ranges into one
    # malformed entry.
    def split_into_entries(input)
      input.split(/[&\n\r;]+/).map { |part| normalize(part) }.compact_blank
    end

    def parse_single_part(part)
      return [] if part.blank?

      day_str, time_str = split_days_and_times(part)
      return [] unless day_str.present? && time_str.present?

      days = parse_days(day_str)
      return [] if days.empty?

      opens_at, closes_at = parse_times_or_247(time_str)

      days.map do |day|
        {
          day: day,
          open_time: opens_at,
          close_time: closes_at,
          closed: opens_at.nil? || closes_at.nil?
        }
      end
    rescue => e
      # A single malformed entry must never abort the whole import; drop it and
      # let the remaining entries (and default-closed days) stand.
      Rails.logger.warn "OfficeHoursParser: skipping unparseable entry #{part.inspect} (#{e.message})" if defined?(Rails)
      []
    end

    # The day specification and the times can be separated by a colon
    # ("Monday - Friday: 8:00 - 16:00"), a dash ("Thursday - Sunday - 10:00 -
    # 15:00") or just whitespace ("Monday - Friday 8:30 - 18:00"). Splitting on
    # ":" breaks the dash/space cases because it hits the colon inside "10:00",
    # so instead locate where the time portion begins — the first digit, or the
    # word "closed"/"24/7"/"24 hours"/"appointment". Everything before it is the
    # day specification; trailing separators are stripped later by parse_days.
    def split_days_and_times(part)
      match = part.match(/\d|closed|24\/7|appointment/i)
      return part.split(":", 2).map(&:strip) unless match

      boundary = match.begin(0)
      [part[0...boundary].strip, part[boundary..].strip]
    end

    def parse_times_or_247(time_str)
      normalized = time_str.to_s.downcase
      return ["00:00", "24:00"] if all_day?(normalized)
      extract_times(time_str)
    end

    def all_day?(normalized)
      normalized.match?(/24\s*\/\s*7/) ||
        normalized.match?(/\b24\s*h(?:ou)?rs?\b/) ||
        normalized.match?(/\ball\s*day\b/) ||
        normalized.match?(/\bopen\s*24\b/)
    end

    def normalize_to_full_week(entries)
      full_schedule = {}

      entries.each do |entry|
        day = entry[:day]
        next if day.blank?

        full_schedule[day] = {
          day: day,
          open_time: entry[:open_time],
          close_time: entry[:close_time],
          closed: entry[:closed]
        }
      end

      DAYS.map do |day|
        full_schedule[day] || {day: day, open_time: nil, close_time: nil, closed: true}
      end
    end

    def normalize_days_to_indexes(entries)
      entries.map do |entry|
        entry.merge(day: DAYS.index(entry[:day]))
      end
    end
  end
end
