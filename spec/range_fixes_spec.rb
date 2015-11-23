require 'range_fixes.rb'

describe Range do
  describe '#intersection' do
    it "returns ranges when there's overlap" do
      expect((1..6) & (2..3)).to eq 2..3  # fully enclosed
      expect((2..3) & (1..6)).to eq 2..3
      expect((1..5) & (2..7)).to eq 2..5  # one end open
      expect((2..7) & (1..5)).to eq 2..5
    end

    it "returns empty ranges when there's no overlap" do
      expect((1..2) & (2..3)).to eq 2..2
      expect((2..3) & (1..2)).to eq 2..2
      expect((1..2) & (3..4)).to eq 2..2
      expect((3..4) & (1..2)).to eq 2..2
    end

    it "works with dates" do
    end
  end

  describe '#empty?' do
    it "works" do
      expect((1..1).empty?).to eq true
      expect((2..1).empty?).to eq true
      expect((1..2).empty?).to eq false
    end

    it "works with dates" do
    end
  end


  describe "#span" do
    it "works" do
      expect((1..5).span).to eq 4
      expect((1..1).span).to eq 0
      expect((1..-1).span).to eq 0
    end

    it "works with dates" do
    end
  end
end
