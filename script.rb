require 'JSON'
require 'time'
require 'yaml'

# screw you stack overflow
#def ranges_overlap?(a, b)
  #a.include?(b.begin) || b.include?(a.begin)
#end

## this doesn't seem to handle exclude_end
#def merge_ranges(a, b)
  #[a.begin, b.begin].min..[a.end, b.end].max
#end

#def merge_overlapping_ranges(ranges)
  #ranges.sort_by(&:begin).inject([]) do |ranges, range|
    #if !ranges.empty? && ranges_overlap?(ranges.last, range)
      #ranges[0...-1] + [merge_ranges(ranges.last, range)]
    #else
      #ranges + [range]
    #end
  #end
#end

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

class Range
  def intersection(other)
    return self.max..self.max if self.max < other.begin
    return other.max..other.max if other.max < self.begin
    [self.begin, other.begin].max..[self.end, other.end].min
  end

  alias_method :&, :intersection
end

# algorithm: round all times down to the nearest 15 mins, add 45 minutes to make a range, merge ranges
json = JSON.parse File.read 'commits.json'
commits = json['commits']

commits = commits.map { |r| r['date'] = time_floor(Time.rfc2822(r['date']), 30); r }
commits = commits.map { |r| r['range'] = (r['date']-30*60)..(r['date'] + 30*60); r }

meetings = json['uncommitted'].map { |v| t=Time.rfc2822(v['date']); v['range']=t..(t+v['duration'].to_i*3600); v }

ranges = commits.map { |r| r['range'] } + meetings.map { |m| m['range'] }

merged = merge_ranges ranges
#puts merged.map { |v| (v.end - v.begin).round }.inspect
#merged = merge_ranges merged.map { |r| time_floor(r.first, 30)..(time_floor(r.last,30)+30) }
#puts merged.map { |v| (v.end - v.begin).round }.inspect

total = merged.reduce(0) { |a,v| a += (v.end - v.begin).round }

merged.each { |r| puts "#{r.begin.strftime '%a'},#{r.begin.strftime '%m-%d'},#{r.begin.strftime '%H:%M'},#{r.end.strftime '%H:%M'},#{(r.end - r.begin) / 3600}" }

puts "total commits=#{commits.count}, time blocks=#{merged.count}, hours=#{total/3600}"

seq_start = Time.parse('30-12-2012')
seq_end = Time.parse('30-03-2013')


#
#     print calendar
#

total = nil
iterate_days seq_start, seq_end do |lo,hi|
  range = lo..hi

  if lo.wday == 0
    print "%10d" % (total/3600) if total
    total = 0
    print "\n%10s" % "#{lo.month}-#{lo.day}"
  end

  today = merged.reduce(0) { |a,v| n = (range & v); a += (n.end - n.begin).round }

  print "%5d" % (today / 3600)
  total += today
end
print "%10d\n" % (total/3600)


#
#     print exhaustive list
#

def select_events range, arr
  arr.select { |o| o['range'].begin >= range.begin && o['range'].begin <= range.end }
end

iterate_days seq_start, seq_end do |lo,hi|
  today = lo..hi

  dow = lo.strftime '%a'
  date = lo.strftime '%m-%d'
  merged.each do |r|
    time = r.begin.strftime '%H:%M'
    dur = ([r.end, hi].min - [r.begin, lo].max) / 3600
    this = today & r
    if this.begin != this.end  # !this.empty?
      events = (select_events(this,commits) + select_events(this,meetings)).sort_by { |e| e['range'].begin }
      events.each do |e|
        puts "#{dow},#{date},#{time},#{dur},\"#{e['comment'].gsub('"', '""')}\",\"#{e['hash'] ? '0x' + e['hash'][0..12] : e['src']}\""
        date = dow = time = dur = ""
      end
    end
  end
end
