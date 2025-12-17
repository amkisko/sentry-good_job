# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob::CronHelpers do
  before do
    perform_basic_setup
  end

  describe "Helpers" do
    describe ".monitor_config_from_cron" do
      it "returns nil for empty cron expression" do
        expect(described_class::Helpers.monitor_config_from_cron("")).to be_nil
      end

      it "returns nil for nil cron expression" do
        expect(described_class::Helpers.monitor_config_from_cron(nil)).to be_nil
      end

      it "creates monitor config for valid cron expression" do
        config = described_class::Helpers.monitor_config_from_cron("0 * * * *")
        expect(config).to be_a(Sentry::Cron::MonitorConfig)
      end

      it "creates monitor config with timezone" do
        config = described_class::Helpers.monitor_config_from_cron("0 * * * *", timezone: "UTC")
        expect(config).to be_a(Sentry::Cron::MonitorConfig)
      end

      it "handles parsing errors gracefully" do
        allow(Fugit).to receive(:parse_cron).and_raise(StandardError.new("Invalid cron"))
        allow(Sentry.configuration.sdk_logger).to receive(:warn)

        result = described_class::Helpers.monitor_config_from_cron("invalid")

        aggregate_failures do
          expect(result).to be_nil
          expect(Sentry.configuration.sdk_logger).to have_received(:warn)
        end
      end
    end

    describe ".monitor_slug" do
      it "converts job name to slug" do
        expect(described_class::Helpers.monitor_slug("TestJob")).to eq("test")
      end

      it "removes _job suffix" do
        expect(described_class::Helpers.monitor_slug("TestJob")).to eq("test")
      end

      it "handles snake_case names" do
        expect(described_class::Helpers.monitor_slug("test_job")).to eq("test")
      end
    end

    describe ".parse_cron_with_timezone" do
      it "returns cron and nil timezone for simple cron" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * *")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to be_nil
        end
      end

      it "extracts timezone from cron with timezone" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * UTC")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("UTC")
        end
      end

      it "extracts complex timezone from cron" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * Europe/Stockholm")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("Europe/Stockholm")
        end
      end

      it "handles invalid timezone format" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * invalid@timezone")
        aggregate_failures do
          expect(cron).to eq("0 * * * * invalid@timezone")
          expect(timezone).to be_nil
        end
      end

      it "returns original cron for short expressions" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * *")
        aggregate_failures do
          expect(cron).to eq("0 * * *")
          expect(timezone).to be_nil
        end
      end

      it "handles multi-slash timezones" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * America/Argentina/Buenos_Aires")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("America/Argentina/Buenos_Aires")
        end
      end

      it "handles GMT offsets" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * GMT-5")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("GMT-5")
        end
      end

      it "handles UTC offsets" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * UTC+2")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("UTC+2")
        end
      end

      it "handles timezones with underscores" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * America/New_York")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("America/New_York")
        end
      end

      it "handles timezones with positive offsets" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * GMT+1")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("GMT+1")
        end
      end

      it "handles timezones with negative offsets" do
        cron, timezone = described_class::Helpers.parse_cron_with_timezone("0 * * * * UTC-8")
        aggregate_failures do
          expect(cron).to eq("0 * * * *")
          expect(timezone).to eq("UTC-8")
        end
      end
    end
  end

  describe "Integration" do
    let(:rails_app) { double("RailsApplication") }
    let(:rails_config) { double("RailsConfig") }
    let(:good_job_config) { double("GoodJobConfig") }

    before do
      stub_const("Rails", double("Rails"))
      allow(Rails).to receive(:application).and_return(rails_app)
      allow(rails_app).to receive(:config).and_return(rails_config)
      allow(rails_config).to receive(:good_job).and_return(good_job_config)
    end

    describe ".setup_monitoring_for_scheduled_jobs" do
      context "when Sentry is not initialized" do
        before do
          allow(Sentry).to receive(:initialized?).and_return(false)
        end

        it "does not set up monitoring" do
          allow(described_class::Integration).to receive(:setup_monitoring_for_job)
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(described_class::Integration).not_to have_received(:setup_monitoring_for_job)
        end
      end

      context "when enable_cron_monitors is disabled" do
        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = false
        end

        it "does not set up monitoring" do
          allow(described_class::Integration).to receive(:setup_monitoring_for_job)
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(described_class::Integration).not_to have_received(:setup_monitoring_for_job)
        end
      end

      context "when cron config is not present" do
        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(nil)
        end

        it "does not set up monitoring" do
          allow(described_class::Integration).to receive(:setup_monitoring_for_job)
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(described_class::Integration).not_to have_received(:setup_monitoring_for_job)
        end
      end

      context "when cron config is present" do
        let(:cron_config) do
          {
            "test_job" => {class: "TestJob", cron: "0 * * * *"},
            "another_job" => {class: "AnotherJob", cron: "0 0 * * *"}
          }
        end

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(cron_config)
        end

        it "sets up monitoring for each job" do
          described_class::Integration.reset_setup_state!
          calls = []
          allow(described_class::Integration).to receive(:setup_monitoring_for_job) do |name, cfg|
            calls << [name, cfg]
          end

          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(calls).to contain_exactly(
            ["test_job", cron_config["test_job"]],
            ["another_job", cron_config["another_job"]]
          )
        end

        it "logs the setup completion" do
          described_class::Integration.reset_setup_state!
          allow(described_class::Integration).to receive(:setup_monitoring_for_job).and_return("TestJob", "AnotherJob")
          allow(Sentry.configuration.sdk_logger).to receive(:info)

          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(Sentry.configuration.sdk_logger).to have_received(:info).with("Sentry cron monitoring setup for 2 scheduled jobs: TestJob, AnotherJob")
        end
      end
    end

    describe ".setup_monitoring_for_job" do
      let(:job_class) { Class.new(ApplicationJob) }

      before do
        allow(Sentry).to receive(:initialized?).and_return(true)
        stub_const("TestJob", job_class)
      end

      context "when job class is missing" do
        let(:job_config) { {class: "NonExistentJob", cron: "0 * * * *"} }

        it "logs a warning and returns" do
          allow(Sentry.configuration.sdk_logger).to receive(:warn)
          # Mock Rails.application.config.after_initialize to execute immediately
          allow(Rails.application.config).to receive(:after_initialize).and_yield

          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/Could not find job class/)
        end
      end

      context "when job config is missing class" do
        let(:job_config) { {cron: "0 * * * *"} }

        it "does not set up monitoring" do
          allow(job_class).to receive(:sentry_monitor_check_ins)
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).not_to have_received(:sentry_monitor_check_ins)
        end
      end

      context "when job config is missing cron" do
        let(:job_config) { {class: "TestJob"} }

        it "does not set up monitoring" do
          allow(job_class).to receive(:sentry_monitor_check_ins)
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).not_to have_received(:sentry_monitor_check_ins)
        end
      end

      context "when job config is complete" do
        let(:job_config) { {class: "TestJob", cron: "0 * * * *"} }

        it "includes monitor check-ins module" do
          allow(job_class).to receive(:include)
          allow(job_class).to receive(:sentry_monitor_check_ins)
          allow(Rails.application.config).to receive(:after_initialize).and_yield
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).to have_received(:include).with(Sentry::Cron::MonitorCheckIns).at_least(:once)
        end

        it "sets up cron monitoring with proper configuration" do
          allow(job_class).to receive(:include)
          allow(job_class).to receive(:sentry_monitor_check_ins)
          # Mock Rails.application.config.after_initialize to execute immediately
          allow(Rails.application.config).to receive(:after_initialize).and_yield
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).to have_received(:sentry_monitor_check_ins)
        end

        it "returns the job name when setup is successful" do
          allow(job_class).to receive(:include)
          allow(job_class).to receive(:sentry_monitor_check_ins)
          # Mock Rails.application.config.after_initialize to execute immediately
          allow(Rails.application.config).to receive(:after_initialize).and_yield

          result = described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(result).to eq("TestJob")
        end
      end
    end

    describe ".add_monitoring_to_job" do
      let(:job_class) { Class.new(ApplicationJob) }

      before do
        allow(Sentry).to receive(:initialized?).and_return(true)
      end

      it "includes cron monitoring module" do
        allow(job_class).to receive(:include)
        allow(job_class).to receive(:sentry_monitor_check_ins)

        described_class::Integration.add_monitoring_to_job(job_class)

        expect(job_class).to have_received(:include).with(Sentry::Cron::MonitorCheckIns).at_least(:once)
      end

      it "sets up cron monitoring with default config" do
        allow(job_class).to receive(:sentry_monitor_check_ins)

        described_class::Integration.add_monitoring_to_job(job_class)

        expect(job_class).to have_received(:sentry_monitor_check_ins)
      end

      it "uses provided slug" do
        allow(job_class).to receive(:sentry_monitor_check_ins)

        described_class::Integration.add_monitoring_to_job(job_class, slug: "custom_slug")

        expect(job_class).to have_received(:sentry_monitor_check_ins).with(hash_including(slug: "custom_slug"))
      end

      it "uses provided cron expression" do
        allow(job_class).to receive(:sentry_monitor_check_ins)

        described_class::Integration.add_monitoring_to_job(job_class, cron_expression: "0 0 * * *")

        expect(job_class).to have_received(:sentry_monitor_check_ins)
      end

      it "logs the setup completion" do
        # JobMonitor removed - no setup needed
        allow(job_class).to receive(:sentry_monitor_check_ins)
        allow(Sentry.configuration.sdk_logger).to receive(:info)

        described_class::Integration.add_monitoring_to_job(job_class)

        expect(Sentry.configuration.sdk_logger).to have_received(:info).with(/Added Sentry cron monitoring/)
      end
    end
  end
end
