# frozen_string_literal: true

module Sentry
  module GoodJob
    # Prepended onto `Sentry::Rails::ActiveJobExtension` on sentry-rails 7.3+
    # so Good Job identity fields attach for any adapter when the job exposes them.
    module RailsActiveJobExtension
      def apply_active_job_context(scope, job)
        super
        good_job = ContextHelpers.add_context(job, {})[:good_job]
        scope.set_contexts(good_job: good_job) if good_job
      end

      def active_job_error_data(job)
        data = super
        good_job = ContextHelpers.add_context(job, {})[:good_job]
        return data unless good_job

        data.merge(
          contexts: data.fetch(:contexts, {}).merge(good_job: good_job)
        )
      end

      def self.install!
        return unless defined?(::Sentry::Rails::ActiveJobExtension)
        return if ::Sentry::Rails::ActiveJobExtension.ancestors.include?(self)

        ::Sentry::Rails::ActiveJobExtension.prepend(self)
      end
    end
  end
end
