module SpreadsheetImport
  module Hours
    # Cuts an hours cell into [day spec, time spec] pairs.
    #
    # Entries are separated by line breaks, semicolons or "&". Each entry is
    # then cut again wherever a new day spec starts *after* a completed time
    # range, which is what keeps the trailing clause of "Mon-Fri 9-5, Sat 10-2"
    # (or the same cell written without the comma) from being folded into its
    # sibling's times.
    class Scanner
      DAY_START = /\b(?:sun|mon|tue|wed|thu|fri|sat|weekday|weekend|daily|every\s*day|all\s*week|business)/i

      # Where the day specification ends and the times begin: the first digit,
      # or the first word that stands in for a time.
      TIME_BOUNDARY = /\d|\bclosed?\b|\bappointment\b|\ball\s*day\b/i

      # "7 days a week" is a day group that happens to start with a digit, so it
      # has to be consumed before the digit boundary above can fire.
      GROUP_PREFIX = /\A7\s*days(?:\s*a\s*week)?\b[\s:.-]*/i

      RANGE_WORD = /\s+(?:to|through|thru|til|till|until)\s+(?=\d|#{DAY_START})/i

      def initialize(input)
        @input = input.to_s
      end

      def call
        entries.flat_map { |entry| segments(entry) }.map { |segment| split_days_and_times(segment) }
      end

      private

      def entries
        @input.split(/[\n\r;]+/)
          .flat_map { |part| split_ampersands(part) }
          .map { |part| normalize(part) }
          .compact_blank
      end

      # "&" separates two schedules only when both sides carry times. In
      # "Sat & Sun 10-2" it is a day-list separator and has to stay put.
      def split_ampersands(part)
        part.split("&").inject([]) do |entries, piece|
          next entries + [piece] if entries.empty? || (entries.last.match?(/\d/) && piece.match?(/\d/))

          entries[0..-2] + ["#{entries.last}&#{piece}"]
        end
      end

      # Fold the many ways a cell writes a range into one delimiter. The word
      # forms are only rewritten when a time or a day follows, so prose like
      # "until further notice" is left alone.
      def normalize(str)
        str.tr("–—", "-").gsub(RANGE_WORD, " - ").gsub(/\s+/, " ").strip
      end

      def segments(entry)
        rest = entry
        found = []
        while (cut = next_cut(rest))
          found << rest[0...cut].strip
          rest = rest[cut..].strip
        end
        found << rest
      end

      def next_cut(text)
        range = TimeSpec::RANGE.match(text)
        return nil if range.nil?

        text.index(DAY_START, range.end(0))
      end

      def split_days_and_times(segment)
        match = TIME_BOUNDARY.match(segment)
        return [segment.strip, ""] if match.nil?

        pair = [segment[0...match.begin(0)].strip, segment[match.begin(0)..].strip]
        pair.first.blank? ? (group_prefix_split(segment) || pair) : pair
      end

      def group_prefix_split(segment)
        match = GROUP_PREFIX.match(segment)
        return nil if match.nil?

        [match[0].strip, segment[match.end(0)..].to_s.strip]
      end
    end
  end
end
