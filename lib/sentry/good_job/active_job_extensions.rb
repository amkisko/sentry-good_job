# frozen_string_literal: true

# GoodJob-specific extensions to sentry-rails ActiveJob integration
# This module enhances sentry-rails ActiveJob with GoodJob-specific functionality:
# - GoodJob-specific context and tags
# - GoodJob-specific span data enhancements
module Sentry
  module GoodJob
    module ActiveJobExtensions
      # Enhance sentry-rails ActiveJob context with GoodJob-specific data
      def self.enhance_sentry_context(job, base_context)
        ContextHelpers.add_context(job, base_context)
      end

      # Set up GoodJob-specific ActiveJob extensions
      def self.setup
        return unless defined?(::Rails) && ::Sentry.initialized?

        # Hook into sentry-rails ActiveJob integration
        if defined?(::Sentry::Rails::ActiveJobExtensions::SentryReporter)
          enhance_sentry_reporter
        end

        # Set up GoodJob-specific ActiveJob extensions
        setup_good_job_extensions
      end

      def self.enhance_sentry_reporter
        return if defined?(@reporter_enhanced) && @reporter_enhanced

        # Enhance the sentry_context method in SentryReporter
        ::Sentry::Rails::ActiveJobExtensions::SentryReporter.class_eval do
          class << self
            alias_method :original_sentry_context, :sentry_context

            def sentry_context(job)
              base_context = original_sentry_context(job)
              Sentry::GoodJob::ActiveJobExtensions.enhance_sentry_context(job, base_context)
            end
          end
        end

        @reporter_enhanced = true
      end

      def self.setup_good_job_extensions
        # Extend ActiveJob::Base with GoodJob-specific functionality
        ActiveSupport.on_load(:active_job) do
          # Add GoodJob-specific attributes and methods
          include GoodJobExtensions

          # Ensure the sentry-rails integration is properly set up
          # by checking if the ActiveJobExtensions module is already included
          if defined?(::Sentry::Rails::ActiveJobExtensions) && !ancestors.include?(::Sentry::Rails::ActiveJobExtensions)
            prepend ::Sentry::Rails::ActiveJobExtensions
          end
        end
      end

      private_class_method :enhance_sentry_reporter, :setup_good_job_extensions

      # GoodJob-specific extensions for ActiveJob
      module GoodJobExtensions
        extend ActiveSupport::Concern

        included do
          around_enqueue do |job, block|
            next block.call unless ::Sentry.initialized?

            if defined?(::Sentry::Rails::ActiveJobExtensions::SentryReporter) &&
                ::Sentry::Rails::ActiveJobExtensions::SentryReporter.respond_to?(:record_producer_span)
              next block.call
            end

            ::Sentry.with_child_span(op: "queue.publish", description: job.class.name) do |span|
              _sentry_set_span_data(span, job)
              block.call
            end
          end

          # GoodJob-specific context is now handled through the enhanced sentry_context method
          # The sentry-rails integration handles error capturing through SentryReporter.record
        end

        private

        # Span fields for this gem's enqueue fallback when sentry-rails
        # record_producer_span is absent. A class-level override of this method
        # shadows the helper; Concern include on ActiveJob::Base cannot wrap it.
        def _sentry_set_span_data(span, job, retry_count: nil)
          return unless span

          span.set_data("messaging.message.id", job.job_id)
          span.set_data("messaging.destination.name", job.queue_name) if job.respond_to?(:queue_name)
          span.set_data("messaging.message.retry.count", retry_count) if retry_count

          latency = calculate_job_latency(job)
          span.set_data("messaging.message.receive.latency", latency) if latency
        end

        # Calculate job latency in milliseconds (GoodJob-specific)
        def calculate_job_latency(job)
          return nil unless job.enqueued_at

          ((Time.now.utc - job.enqueued_at) * 1000).to_i
        end
      end
    end
  end
end
