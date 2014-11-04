class Invoice
  attr_accessor :invoice_number, :start_date, :end_date, :submit_date, :invoice_amount,
    :cleared_date, :check_amount, :check_number
  attr_accessor :range, :events

  # the relative date so you don't have to specify years in the totals file
  # (intentionally different from $base_time so only used in TOTALS file)
  @@base_time = nil

  def initialize fields
    self.invoice_number = fields.shift.sub!(/^0+/, '')
    self.start_date     = parse_time(fields.shift)
    self.end_date       = parse_time(fields.shift)
    self.submit_date    = parse_time(fields.shift)
    self.cleared_date   = parse_time(fields.shift)
    self.invoice_amount = parse_currency(fields.shift)
    self.check_amount   = parse_currency(fields.shift)

    beg_time = Time.new(start_date.year, start_date.month, start_date.day,
                        0, 0, 0, start_date.utc_offset) + 6*60*60
    end_time = Time.new(seq_end.year, seq_end.month, seq_end.day,
                        0, 0, 0, seq_start.utc_offset) + 6*60*60  # note: use seq_start's time zone
    self.range = beg_time...(end_time + 86400)
  end

  def parse_time str
    if @@base_time
      date = Time.parse(str, @@base_time)
    else
      raise 'First date must include full year' unless str =~ /\d\d\d\d/
      date = Time.parsejjjG(str)
    end

    @@base_time = date
    date
  end

  def parse_amount str
    raise 'invalid currency' unless str =~ /(?=.)^\$?(([1-9][0-9]{0,2}(,[0-9]{3})*)|[0-9]+)?(\.[0-9]{1,2})?$/
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

  def grid_data
    result = []
    iterate_days do |today|
    end
  end
end


class Invoice::Day
end

