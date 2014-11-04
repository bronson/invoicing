#!/usr/bin/env ruby

require 'JSON'
require 'time'
require 'yaml'

require_relative 'invoice'


class Range
  def intersection(other)
    return self.end..self.end if self.end < other.begin
    return other.end..other.end if other.end < self.begin
    [self.begin, other.begin].max..[self.end, other.end].min
  end

  def empty?
    self.begin == self.end
  end

  alias_method :&, :intersection
end



def time_floor t,mins
  Time.at(t.to_i/(mins*60)*(mins*60))
end

def merge_ranges(ranges)
  ranges = ranges.sort_by {|r| r.first }
  *outages = ranges.shift
  ranges.each do |r|
    lastr = outages[-1]
    if lastr.last >= r.first - 3600   # merges two blocks if they're less than an hour apart
      outages[-1] = lastr.first..[r.last, lastr.last].max
    else
      outages.push(r)
    end
  end
  outages
end

# warning: if you're iterating days or larger, daylight savings time will screw you up
def iterate_time start_time, end_time, step
  begin
    yield(start_time)
  end while (start_time += step) <= end_time
end

# won't get fooled by DST.
def iterate_days seq_start, seq_end
  time = Time.new(seq_start.year, seq_start.month, seq_start.day, 0, 0, 0, seq_start.utc_offset) + 6*60*60
  end_time = Time.new(seq_end.year, seq_end.month, seq_end.day, 0, 0, 0, seq_start.utc_offset) + 6*60*60  # note: use seq_start's time zone
  while time <= end_time
    otime = time
    time += 86400
    yield Time.new(otime.year, otime.month, otime.day), Time.new(time.year, time.month, time.day)
  end
end

# click everything to the nearest half hour
def timeparse time
  tt ||= Time.rfc2822(time) rescue nil
  tt ||= Time.iso8601(time) rescue nil
  tt ||= Time.strptime(time, "%Y-%m-%d %T %z") rescue nil

  if !tt
    if $base_time
      # base_time has been set so try parsing a relative time
      # todo: I should be a lot stricter about parsing invalid times
      tt = Time.parse(time, $base_time)   # try a relative time
      tt += 86400 if $base_time && $base_time > tt  # if base_time is 11:30 and tt is 00:00, tt needs to be bumped to the following day
      tt = Time.new(tt.year+1, tt.month, tt.day, tt.hour, tt.min, tt.sec, tt.utc_offset) if $base_time && $base_time > tt
    else
      raise "the first time in the file must be rfc or iso: #{time}"
    end
  end

  $base_time = tt

  raise "Invalid time #{time}" if tt.nil?
  time_floor(tt, 30);   # magic value
end


results = []
Dir['*.json'].each do |file|
  $base_time = nil
  json = JSON.parse File.read(file)
  json.reject! { |x| x == {} }
  json.each { |r|
    r['date'] = timeparse(r['date'])             # magic value
    r['end'] = timeparse(r['end']) + 30*60 if r['end']   # magic value
    r['comment'].strip!
  }
  results.concat json
end


Dir['*.lines'].each do |file|
  $base_time = nil
  File.open(file).each do |line|
    next if line =~ /^\s*$/ # blank lines
    next if line =~ /^\s*#/ # comments

    unless $base_time
      $base_time = timeparse(line)
      next
    end

    # todo: should probably choose a line format that more clearly identifies errors
    m = line.match(/^\s*([^-]+)-(.*):([^0-9].*)$/)
    raise "can't match line: #{line}" unless m

    obj = {
      'date' => timeparse(m[1]),
      'end' => timeparse(m[2]),
      'comment' => m[3].strip
    }
    results << obj
  end
end

seq_start = Time.parse('16-03-2014')
seq_end = Time.parse('23-08-2014')

Dir['*.emails'].each do |name|
  File.open(name) do |file|
    loop do
      line = file.gets until file.eof? || line =~ /^From: Scott Bronson/
      break if file.eof?

      line = file.gets
      next unless line =~ /^Subject: (.*)$/
      comment = $1

      line = file.gets
      raise "wanted Date: not #{line}" unless line =~ /^Date: (.*)$/
      date = time_floor(Time.parse($1), 30)

      next unless date >= seq_start

      line = file.gets
      raise "wanted To: not #{line}" unless line =~ /^To: (.*)$/ || line =~ /^Cc: (.*)$/
      to = $1

      obj = {
        'date' => date,
        'comment' => comment,
        'to' => to
      }
      results << obj
    end
  end
end


# then try to establish a range
results.each { |r|
  if r['end']
    r['range'] = r['date']..r['end']
  elsif r['duration']
    r['range'] = r['date']..(r['date'] + 3600*r['duration'].to_i)
  else
    # just assume it took 1/2 hour
    r['range'] = r['date']..(r['date'] + 30*60);  # magic value -- assume task duration of 30 minutes
  end
}

results.sort_by! { |r| r['range'].min }

puts "EVENTS:"
results.each { |r| puts "#{r['range']}:#{"%8s " % (r['hash'] || (r['to'] && r['to'][0..7]))} #{r['comment']}" }

ranges = results.map { |r| r['range'] }
merged = merge_ranges(ranges)

total = merged.reduce(0) { |a,v| a += (v.end - v.begin).round }

puts "\nRANGES:"
merged.each { |r|
  puts "#{r.begin.strftime '%a'} #{r.begin.strftime '%m-%d'}: #{r.begin.strftime '%H:%M'}-#{r.end.strftime '%H:%M'} #{(r.end - r.begin) / 3600}" +
    "#{ '+' if r.begin.day != r.end.day }#{ ' !' if r.end - r.begin > 8*60*60 }"
}

puts
puts "total results=#{results.count}, time blocks=#{merged.count}, hours=#{total/3600.0}"



#
#     print calendar
#

total = nil
print "\n              Sun  Mon  Tue  Wed  Thu  Fri  Sat"
iterate_days seq_start, seq_end do |lo,hi|
  range = lo..hi

  if lo.wday == 0
    print "%10d" % (total/3600) if total
    total = 0
    print "\n%10s  " % "#{lo.day} #{lo.strftime('%b')}"
  end

  today = merged.reduce(0) { |a,v|
    n = range & v
    a += n.end - n.begin
  }

  print "%5.1f" % (today / 3600.0)
  total += today
end
print "%10.1f\n" % (total/3600.0)


#
#     print exhaustive list
#

def select_events range, arr
  arr.select { |o| o['range'].begin >= range.begin && o['range'].begin <= range.end }
end

File.open("out.csv", 'w') do |file|
  iterate_days seq_start, seq_end do |lo,hi|
    today = lo..hi

    dow = lo.strftime '%a'
    date = lo.strftime '%m-%d'
    merged.each do |r|
      beg = [r.begin, lo].max
      time = beg.strftime '%H:%M'
      dur = ([r.end, hi].min - [r.begin, lo].max) / 3600
      fin = (beg + dur*3600).strftime '%H:%M'
      this = today & r

      if this.begin != this.end  # !this.empty?
        events = select_events(this,results).sort_by { |e| e['range'].begin }
        events.each do |e|
          file.puts "#{dow},#{date},#{time},#{fin},#{dur},\"#{e['comment'].gsub('"', '""')}\",\"#{e['hash'] ? '0x' + e['hash'][0..12] : e['src']}\""
          date = dow = time = fin = dur = ""
        end
      end
    end
  end
end


invoices = []
events = results.dup
File.foreach("TOTALS").with_index do |line,i|
  fields = line.split(/\s*,\s*/).map(&:strip)
  next unless fields.first =~ /^0*[1-9]/  # skip this line if it doesn't look like an invoice number

  invoice = Invoice.new(fields,i)
  events_for_invoice,events = events.partition { |o|
    intersection = o['range'] & invoice.range
    !intersection.empty?
  }
  invoice.compute_events(events_for_invoice)
  invoices << invoice
end


puts "You have #{events.count} uncovered events!!" unless events.empty?

# make sure invoice numbers don't conflict
invoices.each.with_object({}) { |a,h|
  raise "Duplicate invoice number: #{a.invoice_number}" if h[a.invoice_number]
  h[a.invoice_number] = a
}
# make sure invoice date ranges don't overlap
invoices.reduce { |a,b|
  interval = a.range & b.range
  raise "Invoices #{a.invoice_number} and #{b.invoice_number} overlap: #{interval}" unless interval.empty?
  b }

invoices.each do |invoice|
end



  # collect events between startdate and enddate
  # ensure they equal the invoice amount (if it exists)

  # FINALLY, do we have uninvoiced events left over?
