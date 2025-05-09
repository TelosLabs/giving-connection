module SpreadsheetImport
  class OfficeHoursParser
    DAYS = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    def initialize(input)
      @input = input.to_s
    end

    def call
      return [] if @input.strip.downcase == "na"

      normalized = normalize(@input)

      chunks = normalized.scan(/([\w\s\-–,]+?)\s*[:\-–]?\s*(Closed|[\d:\s]+[\-\–]\s*[\d:\s]+)/i)

      chunks.flat_map do |day_part, time_part|
        days = extract_days(day_part)
        opens_at, closes_at = extract_times(time_part)

        days.map do |day|
          {
            day: day,
            opens_at: opens_at,
            closes_at: closes_at
          }
        end
      end
    end

    private

    def normalize(str)
      str.gsub(/[–—]/, '-') # convert en/em dashes to hyphen
        .gsub(/[ ]+/, ' ')  # remove non-breaking space
        .gsub(/\s+/, ' ')   # collapse multiple spaces
        .strip
    end

    def extract_days(day_str)
      day_str = day_str.strip.gsub(/[:\-]+$/, '')
      parts = day_str.split(',').map(&:strip)

      parts.flat_map do |part|
        if part.include?('-')
          start_day, end_day = part.split('-').map { |d| standardize_day(d) }
          days_between(start_day, end_day)
        else
          [standardize_day(part)]
        end
      end
    end

    def extract_times(time_str)
      return [nil, nil] if time_str.strip.downcase == 'closed'

      times = time_str.strip.split(/[\-–]/).map(&:strip)
      [normalize_time(times[0]), normalize_time(times[1])]
    end

    def days_between(start_day, end_day)
      return [] unless start_day && end_day
      start_index = DAYS.index(start_day)
      end_index = DAYS.index(end_day)
      return [] unless start_index && end_index
      if start_index <= end_index
        DAYS[start_index..end_index]
      else
        DAYS[start_index..-1] + DAYS[0..end_index]
      end
    end

    def standardize_day(str)
      DAYS.find { |d| d.casecmp(str.strip.capitalize).zero? }
    end

    def normalize_time(time)
      return nil if time.blank?
      Time.parse(time).strftime("%H:%M") rescue nil
    end
  end
end