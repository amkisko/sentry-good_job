# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Sentry::GoodJob::RailsActiveJobExtension" do
  before do
    begin
      require "sentry-rails"
    rescue LoadError
      skip "sentry-rails is not in this bundle"
    end
    skip "sentry-rails ActiveJobExtension is not loaded" unless defined?(::Sentry::Rails::ActiveJobExtension)

    perform_basic_setup
    require "sentry/good_job/rails_active_job_extension"
    Sentry::GoodJob::RailsActiveJobExtension.install!
  end

  let(:extension) { Sentry::Rails::ActiveJobExtension.new }

  let(:job) do
    Class.new(ActiveJob::Base) do
      def self.name
        "BillingJob"
      end

      def good_job_labels
        ["billing"]
      end
    end.new.tap do |instance|
      instance.queue_name = "mailers"
      instance.executions = 2
      instance.priority = 5
      instance.enqueued_at = Time.utc(2024, 1, 1)
    end
  end

  it "merges good_job fields into error contexts", :aggregate_failures do
    data = extension.send(:active_job_error_data, job)

    expect(data[:contexts][:good_job]).to include(
      queue_name: "mailers",
      executions: 2,
      labels: ["billing"]
    )
  end

  it "sets good_job context on the scope" do
    extension.send(:apply_active_job_context, Sentry.get_current_scope, job)

    expect(Sentry.get_current_scope.contexts[:good_job]).to include(
      queue_name: "mailers",
      labels: ["billing"]
    )
  end
end
