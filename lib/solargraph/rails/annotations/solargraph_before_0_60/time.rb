class Time
  # @return [-1, 0, 1, nil]
  def compare_without_coercion(other); end

  # @return [-1, 0, 1, nil]
  def <=>(other); end

  # @param other [Time, ActiveSupport::TimeWithZone, DateTime, Numeric, ActiveSupport::Duration]
  # @return [Float, Time]
  def -(other); end

  # @param other [Time, Numeric, ActiveSupport::Duration]
  # @return [Float, Time]
  def minus_without_coercion(other); end

  # @return [Time]
  def +(other); end

  # @param seconds [Integer, Float]
  # @param microseconds [Integer]
  # @param utc [Boolean]
  # @return [Time]
  def self.at(seconds, microseconds = 0, utc = false); end

  # @return [Time]
  def to_time; end
end

# @!override Time#+
#   @return [Time]

# @!override Time#blank?
#   @return [Boolean]
# @!override Time#acts_like_time?
#   @return [Boolean]
