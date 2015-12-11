require 'event'

# TODO: get rid of the idiotic @@all global.  Probably make a Schedule class
# that is a collection of time ranges.

# A time range is a contiguous series of events.  It has a beginning,
# an end, and one or more events that ocurred during it.

class TimeRange
  attr_reader :range, :events
  @@all = []

  def initialize event
    @range = event.range
    @events = [event]
  end

  def add event
    raise "events out of order: #{event.range.begin} < #{@range.begin}" if event.range.begin < @range.begin
    @range = @range.begin...[@range.end, event.range.end].max
    @events << event
  end

  def end
    range.end
  end

  def begin
    range.begin
  end

  def hours
    range.span / 3600.0
  end

  def to_s
    "#{range.to_s}: #{events.map(&:to_s)}"
  end

  # returns the comment for the longest duration task in the range
  # and gives an indication of how many others there were in the same range
  def tasks max_len
    events_by_duration = events.sort_by { |event| event.range.span }
    result = [events_by_duration.pop.comment]

    loop do
      size = result.map { |r| r.length }.reduce(:+) || 0
      break if events_by_duration.empty? || size+events_by_duration.last.comment.length > max_len-4
      result << events_by_duration.pop.comment
    end

    addl = events.count-1 if events.count > 1
    [result.join(", "), addl]
  end

  def self.all
    @@all
  end

  def self.merge_events
    prev = nil
    Event.all.each do |event|
      separation = 1800 # if events are separated by this many seconds or less, merge them
      if prev && prev.range.end >= event.range.begin - separation
        prev.add(event)
      else
        # otherwise start a new range
        prev = TimeRange.new(event)
        @@all << prev
      end
    end
    @@all.sort_by! { |e| e.range.begin }
  end

  # used to distribute event ranges into time ranges.
  # returns two arrays: matches (events within the time range), and nomatches (everything else)
  def self.partition event_ranges, time_range
    event_ranges.partition { |o| time_range.cover?(o.begin) }
  end
end
