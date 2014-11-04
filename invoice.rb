class Invoice
  attr_reader :invoice_number, :start_date, :end_date, :submit_date, :invoice_amount,
    :cleared_date, :check_amount, :check_number
  attr_reader :range, :events, :line_number, :days

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

  def compute_events events
    @events = events
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
    (range.begin.to_i...range.end.to_i).step(86400).map { |n| Time.at(n) }
  end

  def grid_data
    result = []
    iterate_days do |today|
    end
  end

  def compute_days
    @days = []
    iterate_days do |today|
      day_events = events.select { |o| !(o.range & today).empty? }
      days << Day.new(today, day_events)
    end
  end


  class Day
    attr_reader :range, :events, :ranges

    def initialize range, events
      @range = range    # time span of this day
      @events = events

      @ranges = []
      merge_ranges
    end

    def merge_ranges
      prev = nil
      events.each do |event|
        if prev && prev.range.end >= event.range.begin - 3600
          # if events are separated by an hour or less, merge them
          prev.add(event)
        else
          # otherwise start a new range
          prev = Range.new(event)
          @ranges << prev
        end
      end
    end
  end


  class Range
    attr_reader :range, :events

    def initialize event
      @range = event.range
      @events = [event]
    end

    def add event
      raise "events out of order: #{event.range.begin} < #{@range.begin}" if event.range.begin < @range.begin
      @range = @range.begin...[@range.end, event.range.end].max
      @events << event
    end
  end
end

