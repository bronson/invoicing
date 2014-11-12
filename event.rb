class Event
  attr_reader :date, :end, :duration, :comment, :hash, :to, :range, :src
  @@all = []

  def initialize args
    @date = args.delete('date')
    @end = args.delete('end')
    @duration = 3600*args.delete('duration').to_i if args['duration']
    @comment = args.delete('comment')
    @hash = args.delete('hash')
    @to = args.delete('to')
    @src = args.delete('src')   # TODO: looks like src is unused?

    raise "Unrecognized param: #{args.inspect}" unless args.empty?
    establish_range

    @@all << self
  end

  def establish_range
    if self.end
      @range = self.date...self.end
    elsif duration
      @range = date...(date + duration)
    else
      # magic value -- assume task duration of 30 minutes
      @range = date...(date + 30*60);
    end
  end

  def self.sort
    @@all.sort_by! { |r| r.range.min }
  end

  def self.all
    @@all
  end
end


class EventRange
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

  # returns the comment for the longest duration task in the range
  # and gives an indication of how many others there were in the same range
  def tasks max_len
    result = []
    events_by_duration = events.sort_by { |event| event.range.span }

    loop do
      size = result.map { |r| r.length }.reduce(:+) || 0
      break if size > max_len-4 || events_by_duration.empty?
      result << events_by_duration.pop.comment
    end

    result << "+#{events.count-1}" if events.count > 1

    result.join(", ")
  end

  def self.all
    @@all
  end

  def self.merge_events
    prev = nil
    Event.all.each do |event|
      if prev && prev.range.end >= event.range.begin - 3600
        # if events are separated by an hour or less, merge them
        prev.add(event)
      else
        # otherwise start a new range
        prev = EventRange.new(event)
        @@all << prev
      end
    end
  end

  # used to distribute event ranges into time ranges.
  # returns two arrays: matches (events within the time range), and nomatches (everything else)
  def self.partition event_ranges, time_range
    event_ranges.partition { |o| time_range.cover?(o.begin) }
  end
end
