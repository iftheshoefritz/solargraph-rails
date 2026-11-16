class Date
  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end
end

class DateTime < Date
  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end

  # @param other [Object]
  # @return [Integer, nil]
  def <=>(other); end
end
