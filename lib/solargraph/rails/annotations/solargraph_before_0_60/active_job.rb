module ActiveJob
  module Callbacks
    # These methods will be included into any Active Job object, adding
    # callbacks for +perform+ and +enqueue+ methods.
    module ClassMethods
      # Defines a callback that will get called right before the
      # job's perform method is executed.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     before_perform do |job|
      #       UserMailer.notify_video_started_processing(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      #
      # @yieldreturn [void]
      # @return [void]
      def before_perform(*filters, &blk); end

      # Defines a callback that will get called right after the
      # job's perform method has finished.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     after_perform do |job|
      #       UserMailer.notify_video_processed(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # @yieldreturn [void]
      # @return [void]
      def after_perform(*filters, &blk); end

      # Defines a callback that will get called around the job's perform method.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     around_perform do |job, block|
      #       UserMailer.notify_video_started_processing(job.arguments.first)
      #       block.call
      #       UserMailer.notify_video_processed(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # You can access the return value of the job only if the execution wasn't halted.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     around_perform do |job, block|
      #       value = block.call
      #       puts value # => "Hello World!"
      #     end
      #
      #     def perform
      #       "Hello World!"
      #     end
      #   end
      #
      # @yieldreturn [void]
      # @return [void]
      def around_perform(*filters, &blk); end

      # Defines a callback that will get called right before the
      # job is enqueued.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     before_enqueue do |job|
      #       $statsd.increment "enqueue-video-job.try"
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # @yieldreturn [void]
      # @return [void]
      def before_enqueue(*filters, &blk); end

      # Defines a callback that will get called right after the
      # job is enqueued.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     after_enqueue do |job|
      #       $statsd.increment "enqueue-video-job.success"
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # @yieldreturn [void]
      # @return [void]
      def after_enqueue(*filters, &blk); end

      # Defines a callback that will get called around the enqueuing
      # of the job.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     around_enqueue do |job, block|
      #       $statsd.time "video-job.process" do
      #         block.call
      #       end
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # @yieldreturn [void]
      # @return [void]
      def around_enqueue(*filters, &blk); end
    end
  end

  module Exceptions
    module ClassMethods
      # Catch the exception and reschedule job for re-execution after so many seconds, for a specific number of attempts.
      # If the exception keeps getting raised beyond the specified number of attempts, the exception is allowed to
      # bubble up to the underlying queuing system, which may have its own retry mechanism or place it in a
      # holding queue for inspection.
      #
      # You can also pass a block that'll be invoked if the retry attempts fail for custom logic rather than letting
      # the exception bubble up. This block is yielded with the job instance as the first and the error instance as the second parameter.
      #
      # ==== Options
      # * <tt>:wait</tt> - Re-enqueues the job with a delay specified either in seconds (default: 3 seconds),
      #   as a computing proc that takes the number of executions so far as an argument, or as a symbol reference of
      #   <tt>:exponentially_longer</tt>, which applies the wait algorithm of <tt>((executions**4) + (Kernel.rand * (executions**4) * jitter)) + 2</tt>
      #   (first wait ~3s, then ~18s, then ~83s, etc)
      # * <tt>:attempts</tt> - Re-enqueues the job the specified number of times (default: 5 attempts) or a symbol reference of <tt>:unlimited</tt>
      #   to retry the job until it succeeds
      # * <tt>:queue</tt> - Re-enqueues the job on a different queue
      # * <tt>:priority</tt> - Re-enqueues the job with a different priority
      # * <tt>:jitter</tt> - A random delay of wait time used when calculating backoff. The default is 15% (0.15) which represents the upper bound of possible wait time (expressed as a percentage)
      #
      # ==== Examples
      #
      #  class RemoteServiceJob < ActiveJob::Base
      #    retry_on CustomAppException # defaults to ~3s wait, 5 attempts
      #    retry_on AnotherCustomAppException, wait: ->(executions) { executions * 2 }
      #    retry_on CustomInfrastructureException, wait: 5.minutes, attempts: :unlimited
      #
      #    retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
      #    retry_on Net::OpenTimeout, Timeout::Error, wait: :exponentially_longer, attempts: 10 # retries at most 10 times for Net::OpenTimeout and Timeout::Error combined
      #    # To retry at most 10 times for each individual exception:
      #    # retry_on Net::OpenTimeout, wait: :exponentially_longer, attempts: 10
      #    # retry_on Net::ReadTimeout, wait: 5.seconds, jitter: 0.30, attempts: 10
      #    # retry_on Timeout::Error, wait: :exponentially_longer, attempts: 10
      #
      #    retry_on(YetAnotherCustomAppException) do |job, error|
      #      ExceptionNotifier.caught(error)
      #    end
      #
      #    def perform(*args)
      #      # Might raise CustomAppException, AnotherCustomAppException, or YetAnotherCustomAppException for something domain specific
      #      # Might raise ActiveRecord::Deadlocked when a local db deadlock is detected
      #      # Might raise Net::OpenTimeout or Timeout::Error when the remote service is down
      #    end
      #  end
      #
      # @yieldreturn [void]
      # @return [void]
      def retry_on(*exceptions, wait: 3.seconds, attempts: 5, queue: nil, priority: nil, jitter: JITTER_DEFAULT); end

      # Discard the job with no attempts to retry, if the exception is raised. This is useful when the subject of the job,
      # like an Active Record, is no longer available, and the job is thus no longer relevant.
      #
      # You can also pass a block that'll be invoked. This block is yielded with the job instance as the first and the error instance as the second parameter.
      #
      # ==== Example
      #
      #  class SearchIndexingJob < ActiveJob::Base
      #    discard_on ActiveJob::DeserializationError
      #    discard_on(CustomAppException) do |job, error|
      #      ExceptionNotifier.caught(error)
      #    end
      #
      #    def perform(record)
      #      # Will raise ActiveJob::DeserializationError if the record can't be deserialized
      #      # Might raise CustomAppException for something domain specific
      #    end
      #  end
      #
      # @yieldreturn [void]
      # @return [void]
      def discard_on(*exceptions); end
    end
  end

  module QueueName
    extend ActiveSupport::Concern

    # Includes the ability to override the default queue name and prefix.
    module ClassMethods
      mattr_accessor :default_queue_name, default: "default"

      # Specifies the name of the queue to process the job on.
      #
      #   class PublishToFeedJob < ActiveJob::Base
      #     queue_as :feeds
      #
      #     def perform(post)
      #       post.to_feed!
      #     end
      #   end
      #
      # Can be given a block that will evaluate in the context of the job
      # so that a dynamic queue name can be applied:
      #
      #   class PublishToFeedJob < ApplicationJob
      #     queue_as do
      #       post = self.arguments.first
      #
      #       if post.paid?
      #         :paid_feeds
      #       else
      #         :feeds
      #       end
      #     end
      #
      #     def perform(post)
      #       post.to_feed!
      #     end
      #   end
      #
      # @return [void]
      def queue_as(part_name = nil, &block); end
    end
  end

  module QueuePriority
    extend ActiveSupport::Concern

    # Includes the ability to override the default queue priority.
    module ClassMethods
      # Specifies the priority of the queue to create the job with.
      #
      #   class PublishToFeedJob < ActiveJob::Base
      #     queue_with_priority 50
      #
      #     def perform(post)
      #       post.to_feed!
      #     end
      #   end
      #
      # Specify either an argument or a block.
      #
      # @return [void]
      def queue_with_priority(priority = nil, &block); end
    end
  end
end
