class ActionMailer::Base
  # @return [self]
  def self.with(**params); end
  #
  # @return [ActionMailer::MessageDelivery]
  def mail(**params); end
end
