# Bowel behaves like a ring buffer.
# The << operator adds an element to the top and removes the last element if necessary.
class Bowel < Array
  attr_reader :max_size
  def initialize(max_size, enum = nil)
    @max_size = max_size
    enum.each { |e| self << e } if enum
  end

  def <<(elm)
    if self.size < @max_size then
      self.unshift(elm)
    else
      self.pop # remove last
      self.unshift(elm)
    end
  end
end