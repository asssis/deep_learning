module RasterFixtures
  def square(left: 12, top: 12, side: 36, outline: false)
    Array.new(4096) do |i|
      x, y = i % 64, i / 64
      outer = x.between?(left, left + side) && y.between?(top, top + side)
      inner = x.between?(left + 2, left + side - 2) && y.between?(top + 2, top + side - 2)
      outer && (!outline || !inner) ? 30 : 255
    end
  end

  def triangle
    Array.new(4096) do |i|
      x, y = i % 64, i / 64
      y.between?(8, 52) && (x - 31).abs <= (y - 8) * 0.5 ? 30 : 255
    end
  end

  def rectangle
    Array.new(4096) { |i| (i % 64).between?(8, 56) && (i / 64).between?(24, 36) ? 30 : 255 }
  end
end
