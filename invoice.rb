class Invoice
  attr_reader :invoice_number, :start_date, :end_date, :submit_date, :invoice_amount,
    :cleared_date, :check_amount, :check_number
  attr_reader :range, :events, :line_number

  # the relative date so you don't have to specify years in the totals file
  # (intentionally different from $base_time so only used in TOTALS file)
  @@base_time = nil

  def initialize fields, lineno
    @invoice_number = fields.shift.sub(/^0+/, '')
    @start_date     = parse_time(fields.shift)
    @end_date       = parse_time(fields.shift)
    @submit_date    = parse_time(fields.shift)
    @invoice_amount = parse_currency(fields.shift)
    @cleared_date   = parse_time(fields.shift)
    @check_amount   = parse_currency(fields.shift)
    @line_number    = lineno

    raise "No start date in #{invoice_number}" if start_date.nil?
    raise "No end date in #{invoice_number} #{self.inspect} #{start_date}" if end_date.nil?

    beg_time = Time.new(start_date.year, start_date.month, start_date.day,
                        0, 0, 0, start_date.utc_offset) + 6*60*60
    end_time = Time.new(end_date.year, end_date.month, end_date.day,
                        0, 0, 0, start_date.utc_offset) + 6*60*60     # note: force same time zone as start_date   TODO: handle this better?
    @range = beg_time...(end_time + 86400)
    @events = []
  end

  def add_events events
    @events.concat(events)
  end

  def parse_time str
    return nil if str.nil? || str.empty? || str =~ /^#/

    if @@base_time
      date = Time.parse(str, @@base_time)
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
    time = range.min
    while time < range.max
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
end


class Invoice::Day
end

