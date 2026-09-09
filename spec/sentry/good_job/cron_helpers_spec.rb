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
          allow(good_job_config).to receive(:enable_cron).and_return(false)
          allow(good_job_config).to receive(:execution_mode).and_return(:external)
        end

        it "does not set up monitoring" do
          allow(described_class::Integration).to receive(:setup_monitoring_for_job)
          allow(Sentry.configuration.sdk_logger).to receive(:warn)
          described_class::Integration.reset_setup_state!
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(described_class::Integration).not_to have_received(:setup_monitoring_for_job)
        end
      end

      context "when cron config is an empty hash" do
        let(:job_class) { Class.new(ApplicationJob) }

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:enable_cron).and_return(false)
          allow(good_job_config).to receive(:execution_mode).and_return(:external)
          stub_const("TestJob", job_class)
        end

        it "logs a warning and still applies a later schedule" do
          allow(good_job_config).to receive(:cron).and_return({})
          allow(Sentry.configuration.sdk_logger).to receive(:warn)
          allow(Sentry.configuration.sdk_logger).to receive(:info)
          described_class::Integration.reset_setup_state!

          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/cron is empty/)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/enable_cron/)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/execution_mode/)

          allow(good_job_config).to receive(:cron).and_return(
            "test_job" => {class: "TestJob", cron: "0 * * * *"}
          )
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(job_class.ancestors).to include(Sentry::Cron::MonitorCheckIns)
        end
      end

      context "when called after initialize with a populated cron hash" do
        let(:job_class) { Class.new(ApplicationJob) }
        let(:cron_config) do
          {
            "test_job" => {class: "TestJob", cron: "0 * * * *"}
          }
        end

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(cron_config)
          allow(good_job_config).to receive(:enable_cron).and_return(true)
          allow(good_job_config).to receive(:execution_mode).and_return(:async)
          stub_const("TestJob", job_class)
          allow(Sentry.configuration.sdk_logger).to receive(:info)
          described_class::Integration.reset_setup_state!
        end

        it "includes monitor check-ins on the job class" do
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(job_class.ancestors).to include(Sentry::Cron::MonitorCheckIns)
        end
      end

      context "when cron job config uses string keys" do
        let(:job_class) { Class.new(ApplicationJob) }
        let(:cron_config) do
          {
            "test_job" => {"class" => "TestJob", "cron" => "0 * * * *"}
          }
        end

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(cron_config)
          allow(good_job_config).to receive(:enable_cron).and_return(true)
          allow(good_job_config).to receive(:execution_mode).and_return(:async)
          stub_const("TestJob", job_class)
          allow(Sentry.configuration.sdk_logger).to receive(:info)
          described_class::Integration.reset_setup_state!
        end

        it "includes monitor check-ins on the job class" do
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(job_class.ancestors).to include(Sentry::Cron::MonitorCheckIns)
        end
      end

      context "when Good Job cron will not run in this process" do
        let(:cron_config) do
          {
            "test_job" => {class: "TestJob", cron: "0 * * * *"}
          }
        end

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(cron_config)
          allow(good_job_config).to receive(:enable_cron).and_return(false)
          allow(good_job_config).to receive(:execution_mode).and_return(:external)
          allow(Sentry.configuration.sdk_logger).to receive(:info)
          allow(Sentry.configuration.sdk_logger).to receive(:warn)
          described_class::Integration.reset_setup_state!
        end

        it "logs that monitors appear after a check-in" do
          allow(described_class::Integration).to receive(:setup_monitoring_for_job).and_return("TestJob")

          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/will not appear until a job check-in runs/)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/enable_cron/)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/execution_mode/)
        end
      end

      context "when Good Job cron enablement depends on CLI options" do
        let(:cron_config) do
          {
            "test_job" => {class: "TestJob", cron: "0 * * * *"}
          }
        end

        before do
          allow(Sentry).to receive(:initialized?).and_return(true)
          Sentry.configuration.good_job.enable_cron_monitors = true
          allow(good_job_config).to receive(:cron).and_return(cron_config)
          allow(good_job_config).to receive(:enable_cron).and_return(false)
          allow(good_job_config).to receive(:execution_mode).and_return(:external)
          allow(GoodJob::CLI).to receive(:within_exe?).and_return(true)
          allow(described_class::Integration).to receive(:setup_monitoring_for_job).and_return("TestJob")
          allow(Sentry.configuration.sdk_logger).to receive(:info)
          allow(Sentry.configuration.sdk_logger).to receive(:warn)
          described_class::Integration.reset_setup_state!
        end

        it "warns that cron enablement cannot be confirmed during Rails boot" do
          described_class::Integration.setup_monitoring_for_scheduled_jobs

          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/cannot confirm whether Good Job cron runs/)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/--enable-cron/)
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
          allow(good_job_config).to receive(:enable_cron).and_return(true)
          allow(good_job_config).to receive(:execution_mode).and_return(:async)
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
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).to have_received(:include).with(Sentry::Cron::MonitorCheckIns).at_least(:once)
        end

        it "sets up cron monitoring with proper configuration" do
          allow(job_class).to receive(:include)
          allow(job_class).to receive(:sentry_monitor_check_ins)
          described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(job_class).to have_received(:sentry_monitor_check_ins)
        end

        it "returns the job name when setup is successful" do
          allow(job_class).to receive(:include)
          allow(job_class).to receive(:sentry_monitor_check_ins)

          result = described_class::Integration.setup_monitoring_for_job("test_job", job_config)

          expect(result).to eq("TestJob")
        end
      end

      context "when the cron schedule is callable" do
        let(:job_config) { {class: "TestJob", cron: ->(last_ran) { last_ran }} }

        it "skips static monitoring without raising during initialization" do
          allow(Sentry.configuration.sdk_logger).to receive(:warn)

          expect do
            described_class::Integration.setup_monitoring_for_job("test_job", job_config)
          end.not_to raise_error

          expect(job_class.ancestors).not_to include(Sentry::Cron::MonitorCheckIns)
          expect(Sentry.configuration.sdk_logger).to have_received(:warn).with(/callable cron schedule/)
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

    describe ".attach_reload_hook_if_available" do
      it "reattaches monitoring to reloaded job classes" do
        reloader = Class.new do
          class << self
            attr_reader :prepare_callback
          end

          def self.to_prepare(&block)
            @prepare_callback = block
          end

          def self.prepare!
            new.instance_exec(&prepare_callback)
          end
        end
        stub_const("ActiveSupport::Reloader", reloader)

        first_job_class = Class.new(ApplicationJob)
        stub_const("ReloadSpecJobs", Module.new)
        stub_const("ReloadSpecJobs::ReloadedJob", first_job_class)

        allow(Sentry).to receive(:initialized?).and_return(true)
        Sentry.configuration.good_job.enable_cron_monitors = true
        allow(good_job_config).to receive(:cron).and_return(
          "reloaded_job" => {class: "ReloadSpecJobs::ReloadedJob", cron: "0 * * * *"}
        )
        allow(good_job_config).to receive(:enable_cron).and_return(true)
        allow(good_job_config).to receive(:execution_mode).and_return(:async)
        allow(Sentry.configuration.sdk_logger).to receive(:info)
        described_class::Integration.instance_variable_set(:@reload_hooked, false)
        described_class::Integration.reset_setup_state!

        described_class::Integration.setup_monitoring_for_scheduled_jobs

        expect(first_job_class.ancestors).to include(Sentry::Cron::MonitorCheckIns)

        reloaded_job_class = Class.new(ApplicationJob)
        stub_const("ReloadSpecJobs::ReloadedJob", reloaded_job_class)

        reloader.prepare!

        expect(reloaded_job_class.ancestors).to include(Sentry::Cron::MonitorCheckIns)
      end
    end
  end
end
