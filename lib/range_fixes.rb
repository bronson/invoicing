# These are some monkeypatches that make the Range class a little nicer to use

class Range
  # returns the overlapping range, or an empty range if there's no overlap
  def intersection(other)
    return self.end..self.end if self.end < other.begin
    return other.end..other.end if other.end < self.begin
    [self.begin, other.begin].max..[self.end, other.end].min
  end

  alias_method :&, :intersection

  def empty?
    self.begin >= self.end
  end

  # Like Range#size but doesn't discriminate against non-Numerics (like Dates)
  def span
    self.end >= self.begin ? self.end - self.begin : 0
  end
end

