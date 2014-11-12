# These are some monkeypatches that make the Range class a little nicer to use

class Range
  def intersection(other)
    return self.end..self.end if self.end < other.begin
    return other.end..other.end if other.end < self.begin
    [self.begin, other.begin].max..[self.end, other.end].min
  end

  def empty?
    # maybe it should be >= ?
    self.begin == self.end
  end

  alias_method :&, :intersection
end

