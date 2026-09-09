module SpreadsheetImport
  # Turns a free-text "hours of operation" cell into the seven OfficeHour rows a
  # location needs.
  #
  # Anything we cannot read yields *no* rows and a message on #warnings. That
  # matters: returning a week of closed rows for an unreadable cell would
  # publish the organization as "Closed" seven days a week and suppress the
  # caller's "no set business hours" fallback, all without telling the operator
  # who ran the import. A cell that says "24 hours" or "by appointment" with no
  # weekly schedule comes back through #non_standard instead.
  class OfficeHoursParser
    DAYS = Hours::DaySpec::DAYS

    BLANK_VALUES = ["", "na", "n/a", "n.a.", "none", "tbd", "unknown", "-", "--", "---"].freeze
    CLOSED_CELL = /\A(?:permanently |temporarily )?closed\.?\z/i
    ALL_DAY_HOURS = ["00:00", "23:59"].freeze

    def initialize(input)
      @input = input.to_s
      @schedule = {}
      @warnings = []
      @non_standard = nil
      @appointment = false
    end

    def call
      @result ||= parse
    end

    # Fragments the parser could not read, phrased for the import log.
    def warnings
      call
      @warnings.uniq
    end

    # "always_open" or "appointment_only" when the cell describes the location
    # as a whole rather than a weekly schedule.
    def non_standard
      call
      @non_standard
    end

    private

    def parse
      return [] if blank_input?
      return closed_week if CLOSED_CELL.match?(@input.strip)

      Hours::Scanner.new(@input).call.each { |day_spec, time_spec| absorb(day_spec, time_spec) }
      return [] if @schedule.empty?
      return week unless appointment_only?

      @non_standard ||= "appointment_only"
      []
    end

    # A cell whose only content is "by appointment" describes the location even
    # when it names the days it applies to, so it must not be published as a
    # week of closed days.
    def appointment_only?
      @appointment && @schedule.each_value.all? { |entry| entry[:closed] }
    end

    def blank_input?
      BLANK_VALUES.include?(@input.tr("–—", "-").strip.downcase)
    end

    def absorb(day_spec, time_spec)
      days = Hours::DaySpec.days_for(day_spec)
      times = Hours::TimeSpec.new(time_spec)
      source = "#{day_spec} #{time_spec}".strip
      note("only the first time range was imported from", source) if times.extra_range?
      apply(days, times.call, source)
    end

    def apply(days, outcome, source)
      case outcome
      when :unparsed then unparsed(source)
      when :all_day then all_day(days)
      when :appointment then appointment(days)
      when :closed then close(days)
      else open_between(days, outcome, source)
      end
    end

    def open_between(days, times, source)
      return unparsed(source) if days.empty?

      write(days, open_time: times.first, close_time: times.last, closed: false)
    end

    # A day named as closed is real data, so it still counts as a parsed cell.
    def close(days)
      write(days, open_time: nil, close_time: nil, closed: true)
    end

    # "Sat by appointment" closes Saturday; a whole cell of it describes the
    # location instead.
    def appointment(days)
      @appointment = true
      return @non_standard ||= "appointment_only" if days.empty?

      close(days)
    end

    # A cell that is all-day for every day (or names no day at all) is the
    # location's standing state. Per-day all-day hours stop one minute short of
    # midnight because a `time` column cannot hold "24:00" — it rolls over to
    # the next day and lands back on 00:00, storing a zero-length window.
    def all_day(days)
      return @non_standard ||= "always_open" if days.empty? || days.size == DAYS.size

      write(days, open_time: ALL_DAY_HOURS.first, close_time: ALL_DAY_HOURS.last, closed: false)
    end

    def write(days, attributes)
      days.each { |day| @schedule[day] = attributes.merge(day: day) }
    end

    def unparsed(source)
      note("Hours not understood:", source)
    end

    # Fragments are reported post-normalization, so name the original cell too
    # whenever the two have drifted apart.
    def note(reason, source)
      cell = @input.strip
      suffix = (source.strip == cell) ? "" : " (from cell #{cell.inspect})"
      @warnings << "#{reason} #{source.strip.inspect}#{suffix}"
    end

    def week
      DAYS.each_with_index.map do |day, index|
        (@schedule[day] || closed_day).merge(day: index)
      end
    end

    def closed_week
      DAYS.each_index.map { |index| closed_day.merge(day: index) }
    end

    def closed_day
      {day: nil, open_time: nil, close_time: nil, closed: true}
    end
  end
end
