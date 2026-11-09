class Date
  # @param form [Symbol]
  # @return [Time]
  def to_time(form = :local); end

  # @return [Rational, self]
  def -(other); end

  # @return [self]
  def +(other); end

  # @return [-1, 0, 1, nil]
  def <=>(other); end

  # @return [::Time]
  def to_time; end
end

# @!override Date#blank?
#   @return [Boolean]
# @!override Date#acts_like_date?
#   @return [Boolean]
# @!override DateTime#blank?
#   @return [Boolean]
# @!override DateTime#acts_like_date?
#   @return [Boolean]
# @!override DateTime#acts_like_time?
#   @return [Boolean]
