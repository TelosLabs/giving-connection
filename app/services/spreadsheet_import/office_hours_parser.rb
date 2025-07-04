module SpreadsheetImport
  class OfficeHoursParser
    DAYS = %w[sunday monday tuesday wednesday thursday friday saturday]

    def initialize(input)
      @input = input.to_s
    end

    def call
      return [] if blank_input?

      parts = split_by_ampersand(normalize(@input))

      parsed_entries = parts.flat_map { |part| parse_single_part(part) }

      full_week = normalize_to_full_week(parsed_entries)

      normalize_days_to_indexes(full_week)
    end

    private

    def normalize(str)
      str.gsub(/[–—]/, "-")
        .gsub(/[ ]+/, " ")
        .gsub(/\s+/, " ")
        .strip
    end

    def parse_days(day_str)
      day_str = day_str.strip.gsub(/[:\-]+$/, "")
      parts = day_str.split(",").map(&:strip)

      parts.flat_map do |part|
        if part.include?("-")
          start_day, end_day = part.split("-").map { |d| standardize_day(d) }
          days_between(start_day, end_day)
        else
          [standardize_day(part)]
        end
      end
    end

    def extract_times(time_str)
      return [nil, nil] if time_str.strip.downcase == "closed"

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
        DAYS[start_index..] + DAYS[0..end_index]
      end
    end

    def standardize_day(str)
      DAYS.find { |d| d.casecmp(str.strip.capitalize).zero? }&.downcase
    end

    def normalize_time(time)
      return nil if time.blank?
      begin
        Time.zone.parse(time).strftime("%H:%M")
      rescue
        nil
      end
    end

    def blank_input?
      @input.strip.downcase == "na"
    end

    def split_by_ampersand(input)
      input.split("&").map(&:strip)
    end

    def parse_single_part(part)
      return [] if part.blank?

      day_str, time_str = split_days_and_times(part)
      return [] unless day_str && time_str

      days = parse_days(day_str) # Now returns ["monday", "tuesday", ...]
      opens_at, closes_at = parse_times_or_247(time_str)

      days.map do |day|
        {
          day: day,
          open_time: opens_at,
          close_time: closes_at,
          closed: opens_at.nil? || closes_at.nil?
        }
      end
    end

    def split_days_and_times(part)
      part.split(":", 2).map(&:strip)
    end

    def parse_times_or_247(time_str)
      return ["00:00", "24:00"] if time_str.downcase == "24/7"
      extract_times(time_str)
    end

    def normalize_to_full_week(entries)
      full_schedule = {}

      entries.each do |entry|
        day = entry[:day].downcase
        full_schedule[day] = {
          day: day,
          open_time: entry[:open_time],
          close_time: entry[:close_time],
          closed: entry[:closed]
        }
      end

      DAYS.map(&:downcase).map do |day|
        full_schedule[day] || {day: day, open_time: nil, close_time: nil, closed: true}
      end
    end

    def default_closed_schedule
      DAYS.map(&:downcase).map do |day|
        {day: day, open_time: nil, close_time: nil, closed: true}
      end
    end

    def normalize_days_to_indexes(entries)
      entries.map do |entry|
        entry.merge(day: DAYS.index(entry[:day]))
      end
    end
  end
end
