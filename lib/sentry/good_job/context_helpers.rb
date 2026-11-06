# frozen_string_literal: true

# Helper methods for adding GoodJob-specific information to Sentry context
# This works WITH sentry-rails, not against it
module Sentry
  module GoodJob
    module ContextHelpers
      # Add GoodJob-specific information to the existing Sentry Rails context
      def self.add_context(job, base_context = {})
        return base_context unless job.respond_to?(:queue_name) && job.respond_to?(:executions)

        # Job arguments stay on sentry-rails via config.data_collection.queues
        base_context.merge(
          good_job: {
            queue_name: job.queue_name,
            executions: job.executions,
            enqueued_at: job.enqueued_at,
            priority: job.respond_to?(:priority) ? job.priority : nil
          }.merge(optional_good_job_fields(job))
        )
      end

      # Manual helper for hosts that set Sentry tags themselves.
      # Setup does not call this; sentry-rails has no tags enhancement hook.
      # Prefer labels in context: dynamic labels can be high-cardinality as tags.
      def self.add_tags(job, base_tags = {})
        return base_tags unless job.respond_to?(:queue_name) && job.respond_to?(:executions)

        good_job_tags = {
          queue_name: job.queue_name,
          executions: job.executions
        }
        good_job_tags[:priority] = job.priority if job.respond_to?(:priority)
        concurrency_key = concurrency_key_for(job)
        good_job_tags[:concurrency_key] = concurrency_key if concurrency_key

        base_tags.merge(good_job_tags)
      end

      def self.optional_good_job_fields(job)
        fields = {}
        fields[:labels] = Array(job.good_job_labels) if job.respond_to?(:good_job_labels)
        # Legacy through good_job 4.x; removed with the concurrency_key column in v5.
        concurrency_key = concurrency_key_for(job)
        fields[:concurrency_key] = concurrency_key if concurrency_key
        fields
      end
      private_class_method :optional_good_job_fields

      def self.concurrency_key_for(job)
        return unless job.respond_to?(:good_job_concurrency_key)

        job.good_job_concurrency_key
      end
      private_class_method :concurrency_key_for
    end
  end
end
