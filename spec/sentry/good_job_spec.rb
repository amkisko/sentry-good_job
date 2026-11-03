# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob do
  before do
    perform_basic_setup
  end

  let(:transport) do
    Sentry.get_current_client.transport
  end

  it "registers the integration" do
    expect(Sentry.integrations).to have_key("good_job")
  end

  it "has the correct version" do
    expect(described_class::VERSION).to eq("7.0.3")
  end

  describe "setup_good_job_integration" do
    before do
      rails_app = double("Rails::Application")
      rails_config = double("Rails::Configuration")
      good_job_config = double("GoodJob::Configuration")

      allow(::Rails).to receive(:application).and_return(rails_app)
      allow(rails_app).to receive(:config).and_return(rails_config)
      allow(rails_config).to receive(:good_job).and_return(good_job_config)
      allow(good_job_config).to receive(:cron).and_return({})
    end

    it "sets up cron monitoring when enable_cron_monitors is true" do
      Sentry.configuration.good_job.enable_cron_monitors = true
      allow(Sentry::GoodJob::CronHelpers::Integration).to receive(:setup_monitoring_for_scheduled_jobs)

      described_class.setup_good_job_integration

      expect(Sentry::GoodJob::CronHelpers::Integration).to have_received(:setup_monitoring_for_scheduled_jobs)
    end

    it "skips cron monitoring when enable_cron_monitors is false" do
      Sentry.configuration.good_job.enable_cron_monitors = false
      allow(Sentry::GoodJob::CronHelpers::Integration).to receive(:setup_monitoring_for_scheduled_jobs)

      described_class.setup_good_job_integration

      expect(Sentry::GoodJob::CronHelpers::Integration).not_to have_received(:setup_monitoring_for_scheduled_jobs)
    end
  end

  describe "capture_exception" do
    it "delegates to Sentry.capture_exception" do
      exception = build_exception
      options = {hint: {background: true}}

      allow(Sentry).to receive(:capture_exception)

      described_class.capture_exception(exception, **options)

      expect(Sentry).to have_received(:capture_exception).with(exception, **options)
    end
  end
end
