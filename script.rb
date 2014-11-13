#!/usr/bin/env ruby

require 'JSON'
require 'time'
require 'yaml'

require_relative 'range_fixes'
require_relative 'event'
require_relative 'invoice'

# to generate html and pdfs
require 'bundler/setup'
require 'wkhtmltopdf/heroku'
require 'pdfkit'
require 'slim'
require 'tilt'



def time_floor t,mins
  Time.at(t.to_i/(mins*60)*(mins*60))
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


def check_cleared_checks invoices
  cleared_checks = {}
  invoice_total = {}

  # ensure check amounts are consistent
  invoices.each do |invoice|
    next unless invoice.check_number
    invoice_total[invoice.check_number] ||= 0
    invoice_total[invoice.check_number] += invoice.invoice_amount

    check = cleared_checks[invoice.check_number]

    if check
      raise "cleared date for invoice #{invoice.invoice_number} must match invoice #{check[:invoice_number]}" unless invoice.cleared_date == check[:cleared_date]
      raise "check amount for invoice #{invoice.invoice_number} must match invoice #{check[:invoice_number]}" unless invoice.check_amount == check[:check_amount]
      raise "check number for invoice #{invoice.invoice_number} must match invoice #{check[:invoice_number]}" unless invoice.check_number == check[:check_number]
    else
      cleared_checks[invoice.check_number] = {
        cleared_date: invoice.cleared_date,
        check_amount: invoice.check_amount,
        check_number: invoice.check_number,
        invoice_number: invoice.invoice_number  # the first invoice that mentions this check
      }
    end
  end

  raise "this is impossible" if cleared_checks.keys.sort != invoice_total.keys.sort

  # ensure invoice amounts add up to the check amount
  invoice_total.each do |num,amt|
    raise "invoices for check #{num} total to #{amt} not #{cleared_checks[num][:check_amount]}" unless amt == cleared_checks[num][:check_amount]
  end
end


Dir['*.json'].each do |file|
  $base_time = nil
  json = JSON.parse File.read(file)
  json.reject! { |x| x == {} }
  json.each do |r|
    r['date'] = timeparse(r['date'])                     # magic value
    r['end'] = timeparse(r['end']) + 30*60 if r['end']   # magic value
    r['comment'].strip!
    Event.new(r)
  end
end


Dir['*.hours'].each do |file|
  $base_time = nil
  File.open(file).each do |line|
    line = line.sub(/#.*$/, '')   # strip comments
    next if line =~ /^\s*$/       # blank lines

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

    Event.new(obj)
  end
end


seq_start = Time.parse('16-03-2014')
seq_end = Time.parse('23-08-2014')

Dir['*.mbox'].each do |name|
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
      Event.new(obj)
    end
  end
end


Event.sort

puts "EVENTS:"
Event.all.each { |r| puts "#{r.range}:#{"%8s " % (r.hash || (r.to && r.to[0..7]))} #{r.comment}" }

EventRange.merge_events

puts "\nRANGES:"
EventRange.all.each { |r|
  puts "#{r.begin.strftime '%a'} #{r.begin.strftime '%m-%d'}: #{r.begin.strftime '%H:%M'}-#{r.end.strftime '%H:%M'} #{(r.end - r.begin) / 3600}" +
    "#{ '+' if r.begin.day != r.end.day }#{ ' !' if r.end - r.begin > 8*60*60 }"
}

puts
total = EventRange.all.reduce(0) { |a,v| a += (v.end - v.begin).round }
puts "total results=#{Event.all.count}, time blocks=#{EventRange.all.count}, hours=#{total/3600.0}"



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

  today = EventRange.all.reduce(0) { |a,v|
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
  arr.select { |o| o.range.begin >= range.begin && o.range.begin <= range.end }
end

File.open("out.csv", 'w') do |file|
  iterate_days seq_start, seq_end do |lo,hi|
    today = lo..hi

    dow = lo.strftime '%a'
    date = lo.strftime '%m-%d'
    EventRange.all.each do |r|
      beg = [r.begin, lo].max
      time = beg.strftime '%H:%M'
      dur = ([r.end, hi].min - [r.begin, lo].max) / 3600
      fin = (beg + dur*3600).strftime '%H:%M'
      this = today & r

      if this.begin != this.end  # !this.empty?
        events = select_events(this,Event.all).sort_by { |e| e.range.begin }
        events.each do |e|
          file.puts "#{dow},#{date},#{time},#{fin},#{dur},\"#{e.comment.gsub('"', '""')}\",\"#{e.hash ? '0x' + e.hash[0..12] : e.src}\""
          date = dow = time = fin = dur = ""
        end
      end
    end
  end
end


invoices = []
ranges = EventRange.all.dup
current_rate = nil

File.foreach("TOTALS").with_index do |line,i|
  line = line.sub(/#.*$/, '')   # strip comments
  fields = line.split(/\s*,\s*/).map(&:strip)
  current_rate = $1.to_f if fields.first =~ /rate: \$?(\d*\.?\d*)\s*\/\s*hour/
  next unless fields.first =~ /^0*[1-9]/  # skip this line if it doesn't look like an invoice number

  invoice = Invoice.new(fields,i,current_rate)
  ranges_for_invoice,ranges = EventRange.partition(ranges, invoice.range)

  invoice.compute_ranges(ranges_for_invoice)
  invoices << invoice
end

count = ranges.reduce(0) { |v,o| v += o.events.size }
puts "\nYou have #{count} uncovered events!" unless count == 0

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

# make sure the total dollar amount matches for each invoice
invoices.each do |invoice|
  if !invoice.invoice_amount.nil? && invoice.computed_amount != invoice.invoice_amount
    raise "Invoice #{invoice.invoice_number}: computed amount #{invoice.computed_amount.inspect} " +
      "doesn't equal invoiced amount #{invoice.invoice_amount}"
  end
end

# make sure each cleared check matches its invoice totals & is consistent
check_cleared_checks(invoices)


stylesheets = %w[
  pocketgrid.css
  styles.css
]

template = Tilt.new('invoice.slim')

invoices.each do |invoice|
  if File.exist?("#{invoice.title}.html") && File.exist?("#{invoice.title}.pdf")
    content = File.read("#{invoice.title}.html")
  end

  html = template.render(invoice, stylesheets: stylesheets)

  if content != html
    puts "Writing #{invoice.title}"
    File.write("#{invoice.title}.html", html)

    # apparently wkhtmltopdf does try to support page-break-inside: avoid
    kit = PDFKit.new(html, page_size: 'Letter', title: invoice.title)
    kit.stylesheets.concat(stylesheets)
    kit.to_file("#{invoice.title}.pdf")
  end
end


