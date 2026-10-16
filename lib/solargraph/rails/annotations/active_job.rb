module ActiveJob
  module QueueName
    extend ActiveSupport::Concern

    module ClassMethods
      mattr_accessor :default_queue_name, default: "default"
    end
  end
end
