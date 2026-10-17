module ActiveJob
  module QueueName
    extend ActiveSupport::Concern

    module ClassMethods
      # Delete once https://github.com/apiology/gem_rbs_collection/pull/9 lands.
      mattr_accessor :default_queue_name, default: "default"
    end
  end
end
