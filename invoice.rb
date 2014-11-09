class Invoice
  attr_reader :invoice_number, :start_date, :end_date, :submit_date, :invoice_amount,
    :cleared_date, :check_amount, :check_number
  attr_reader :range, :event_ranges, :line_number, :days

  # the relative date so you don't have to specify years in the totals file
  # (intentionally different from $base_time so only used in TOTALS file)
  @@base_time = nil

  def initialize fields, lineno
    @invoice_number = fields.shift.sub(/^0+/, '')
    @start_date     = parse_time(fields.shift)
    old_base = @@base_time

    @end_date       = parse_time(fields.shift)
    @submit_date    = parse_time(fields.shift)
    @invoice_amount = parse_currency(fields.shift)
    @cleared_date   = parse_time(fields.shift)
    @check_amount   = parse_currency(fields.shift)
    @line_number    = lineno

    raise "No start date in #{invoice_number}" if start_date.nil?
    raise "No end date in #{invoice_number} #{self.inspect} #{start_date}" if end_date.nil?

    beg_time = Time.new(start_date.year, start_date.month, start_date.day,
                        0, 0, 0, start_date.utc_offset)
    end_time = Time.new(end_date.year, end_date.month, end_date.day,
                        0, 0, 0, start_date.utc_offset)
    @range = beg_time...(end_time + 86400)

    # reset base_time back to start_date.  otherwise it might be the cleared date,
    # which is probably after the following invoice's start date, so we'd increment
    # the year thinking we wrapped.  that gets ridiculous quick.
    @@base_time = old_base
  end

  def compute_ranges ranges
    @event_ranges = ranges
    compute_days
  end

  def parse_time str
    return nil if str.nil? || str.empty? || str =~ /^#/

    if @@base_time
      date = Time.parse(str, @@base_time)
      date += 86400 if @@base_time && @@base_time > date  # if base_time is 11:30 and tt is 00:00, tt needs to be bumped to the following day
      # if base_time is Dec 20 and date is Jan 4, then we know it needs to be January of the following year
      date = Time.new(date.year+1, date.month, date.day, date.hour, date.min, date.sec, date.utc_offset) if @@base_time && @@base_time > date
    else
      raise 'First date must include full year' unless str =~ /\d\d\d\d/
      date = Time.parse(str)
    end

    @@base_time = date
    date
  end

  def parse_currency str
    return nil if str.nil? || str.empty? || str =~ /^#/
    raise "invalid currency: #{str}" unless str =~ /(?=.)^\$?(([1-9][0-9]{0,2}(,[0-9]{3})*)|[0-9]+)?(\.[0-9]{1,2})?$/
    str.gsub(/\$|,/, '').to_f
  end

  def cover? date
    range.cover?(date)
  end

  def iterate_days
    time = range.begin
    while time < range.end
      otime = time
      time += 86400
      yield Time.new(otime.year, otime.month, otime.day)...Time.new(time.year, time.month, time.day)
    end
  end

  def day_array
    (range.begin.to_i...range.end.to_i).step(86400).map { |n| Time.at(n)...Time.at(n+86400) }
  end

  def compute_days
    @days ||= begin
      day_array.map do |today|
        day_events,* = EventRange.partition(event_ranges, today)
        Day.new(today, day_events)
      end
    end
  end

  def hours
    Day.hours event_ranges
  end


  class Day
    attr_reader :range, :event_ranges

    def initialize range, event_ranges
      @range = range    # time span of this day
      @event_ranges = event_ranges
    end

    def hours
      self.class.hours event_ranges
    end

    def self.hours event_ranges
      event_ranges.reduce(0) { |sum,range| sum + range.hours }
    end
  end
end

