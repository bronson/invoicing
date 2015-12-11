require 'mail'


# An event is a single thing that happened, and that took some amount
# of time.  It could be a 20 minute conference call or an 8 hour git commit.

class Event
  attr_reader :date, :end, :duration, :comment, :hash, :to, :range, :src
  @@all = []

  include Comparable
  def <=>(other)
    [date, hash||'', comment] <=> [other.date, other.hash||'', other.comment]
  end

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

  def self.all
    @@all
  end

  def hours
    range.span / 3600.0
  end

  def to_addr
    a = Mail::Address.new(to)
    a.address
  end

  def full_comment
    str = comment
    str += " (#{hash})" if hash
    str += " (to: #{to_addr})" if to
    str
  end

  def to_s
    "#{range.to_s}-#{hash || comment}"
  end
end
