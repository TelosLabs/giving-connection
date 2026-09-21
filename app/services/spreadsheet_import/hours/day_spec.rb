module SpreadsheetImport
  module Hours
    # Resolves the day portion of an hours cell ("Mon-Fri", "Weekdays & Sat",
    # "MWF") into canonical day names.
    #
    # Every recognized day is returned, not just the first one — a spec that
    # names three days yields three days. The flip side is that a spec is only
    # accepted when *all* of its parts resolve, so prose like "W/ appointment"
    # is rejected outright rather than quietly contributing a Wednesday.
    class DaySpec
      DAYS = %w[sunday monday tuesday wednesday thursday friday saturday].freeze

      ALIASES = {
        "sunday" => "sunday", "sun" => "sunday", "su" => "sunday", "u" => "sunday",
        "monday" => "monday", "mon" => "monday", "mo" => "monday", "m" => "monday",
        "tuesday" => "tuesday", "tues" => "tuesday", "tue" => "tuesday", "tu" => "tuesday", "t" => "tuesday",
        "wednesday" => "wednesday", "weds" => "wednesday", "wed" => "wednesday", "we" => "wednesday", "w" => "wednesday",
        "thursday" => "thursday", "thurs" => "thursday", "thur" => "thursday", "thu" => "thursday",
        "thr" => "thursday", "th" => "thursday", "r" => "thursday",
        "friday" => "friday", "fri" => "friday", "fr" => "friday", "f" => "friday",
        "saturday" => "saturday", "sat" => "saturday", "sa" => "saturday"
      }.freeze

      # Keyword groups that expand to a set of days on their own.
      GROUPS = {
        "weekday" => %w[monday tuesday wednesday thursday friday],
        "weekdays" => %w[monday tuesday wednesday thursday friday],
        "businessday" => %w[monday tuesday wednesday thursday friday],
        "businessdays" => %w[monday tuesday wednesday thursday friday],
        "weekend" => %w[saturday sunday],
        "weekends" => %w[saturday sunday],
        "daily" => DAYS,
        "everyday" => DAYS,
        "allweek" => DAYS,
        "7days" => DAYS,
        "7daysaweek" => DAYS
      }.freeze

      # Compressed initial runs ("MWF", "TTh", "MTWThF"). Two-letter aliases are
      # listed first so "th" wins over a bare "t" at the same position.
      INITIALS = /th|tu|sa|su|mo|we|fr|[mtwrfu]/
      INITIAL_RUN = /\A(?:#{INITIALS})+\z/

      SEPARATORS = /[,\/&+]|\band\b/i

      def self.days_for(spec)
        new(spec).days
      end

      def initialize(spec)
        @spec = spec.to_s.downcase.gsub(/[:\-\s.]+\z/, "").strip
      end

      # An empty list means "this is not a day specification" — the caller
      # reports it rather than guessing.
      def days
        return initials_days if parts.one? && resolved.first.empty?
        return [] if resolved.any?(&:empty?)
        resolved.flatten.uniq
      end

      private

      def parts
        @parts ||= @spec.split(SEPARATORS).map(&:strip).compact_blank
      end

      def resolved
        @resolved ||= parts.map { |part| days_in(part) }
      end

      def days_in(part)
        group = GROUPS[part.delete(". ")]
        return group.dup if group

        part.include?("-") ? range_days(part) : token_days(part)
      end

      # Two bounds are a range ("Mon-Fri"); three or more are a list written
      # with the wrong separator ("Mon-Wed-Fri").
      def range_days(part)
        tokens = part.split("-").map(&:strip).compact_blank
        bounds = tokens.map { |token| token_days(token).first }
        return [] if bounds.empty? || bounds.any?(&:nil?)
        return bounds if bounds.size > 2

        days_between(bounds.first, bounds.last)
      end

      def token_days(part)
        part.delete(".").scan(/[a-z]+/).filter_map { |token| ALIASES[token] }
      end

      def days_between(start_day, end_day)
        start_index = DAYS.index(start_day)
        end_index = DAYS.index(end_day)
        return [] unless start_index && end_index
        return DAYS[start_index..end_index] if start_index <= end_index

        DAYS[start_index..] + DAYS[0..end_index]
      end

      def initials_days
        run = @spec.delete("^a-z")
        return [] unless run.length.between?(2, 7) && run.match?(INITIAL_RUN)

        run.scan(INITIALS).filter_map { |initial| ALIASES[initial] }.uniq
      end
    end
  end
end
