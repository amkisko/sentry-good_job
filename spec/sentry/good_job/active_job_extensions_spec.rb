# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob::ActiveJobExtensions do
  before do
    perform_basic_setup
    described_class.setup
  end

  describe ".enhance_sentry_context" do
    it "adds GoodJob data when job exposes GoodJob attributes", :aggregate_failures do
      job = Struct.new(:queue_name, :executions, :enqueued_at, :priority).new("default", 2, Time.utc(2024, 1, 1), 5)
      base = {foo: "bar"}

      result = described_class.enhance_sentry_context(job, base)

      expect(result[:good_job]).to include(queue_name: "default", executions: 2, enqueued_at: Time.utc(2024, 1, 1), priority: 5)
      expect(result[:foo]).to eq("bar")
    end

    it "returns base context when job lacks GoodJob attributes" do
      base = {foo: "bar"}

      result = described_class.enhance_sentry_context(double("Job"), base)

      expect(result).to eq(base)
    end
  end

  describe ".enhance_sentry_tags" do
    it "adds GoodJob tags when job exposes GoodJob attributes", :aggregate_failures do
      job = Struct.new(:queue_name, :executions, :priority).new("critical", 3, 10)
      base = {existing: "tag"}

      result = described_class.enhance_sentry_tags(job, base)

      expect(result).to include(queue_name: "critical", executions: 3, priority: 10, existing: "tag")
    end

    it "returns base tags when job lacks GoodJob attributes" do
      base = {existing: "tag"}

      result = described_class.enhance_sentry_tags(double("Job"), base)

      expect(result).to eq(base)
    end
  end

  describe "around_enqueue hook" do
    it "creates a span with GoodJob-specific data when Sentry is initialized", :aggregate_failures do
      job = HappyJob.new
      job.instance_variable_set(:@enqueued_at, Time.at(0))

      span = instance_double(Sentry::Span, set_data: nil)
      allow(Sentry).to receive(:with_child_span).and_yield(span)
      allow(Time).to receive(:now).and_return(Time.at(1))

      block_called = false
      job.send(:run_callbacks, :enqueue) { block_called = true }

      expect(block_called).to be(true)
      expect(span).to have_received(:set_data).with("messaging.message.id", job.job_id)
      expect(span).to have_received(:set_data).with("messaging.destination.name", job.queue_name)
      expect(span).to have_received(:set_data).with("messaging.message.receive.latency", 1000)
    end

    it "skips span creation when Sentry is not initialized" do
      allow(Sentry).to receive(:initialized?).and_return(false)
      job = HappyJob.new

      span = instance_double(Sentry::Span)
      allow(Sentry).to receive(:with_child_span).and_yield(span)

      job.send(:run_callbacks, :enqueue) {}

      expect(Sentry).not_to have_received(:with_child_span)
    end
  end

  describe "#_sentry_set_span_data fallback" do
    it "adds GoodJob-specific span data when no super implementation exists", :aggregate_failures do
      job = HappyJob.new
      job.instance_variable_set(:@enqueued_at, Time.at(0))
      span = instance_double(Sentry::Span, set_data: nil)

      allow(Time).to receive(:now).and_return(Time.at(1))

      job.send(:_sentry_set_span_data, span, job, retry_count: 3)

      expect(span).to have_received(:set_data).with("messaging.message.id", job.job_id)
      expect(span).to have_received(:set_data).with("messaging.destination.name", job.queue_name)
      expect(span).to have_received(:set_data).with("messaging.message.retry.count", 3)
      expect(span).to have_received(:set_data).with("messaging.message.receive.latency", 1000)
    end

    it "calls the super implementation when present while preserving GoodJob data", :aggregate_failures do
      base_class = Class.new(ApplicationJob) do
        attr_accessor :enqueued_at

        def _sentry_set_span_data(span, job, retry_count: nil)
          span.set_data("base", true)
        end
      end

      subclass = Class.new(base_class) do
        include Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions
      end

      job = subclass.new
      job.enqueued_at = Time.at(0)

      span = instance_double(Sentry::Span, set_data: nil)
      allow(Time).to receive(:now).and_return(Time.at(1))

      job.send(:_sentry_set_span_data, span, job, retry_count: 1)

      expect(span).to have_received(:set_data).with("base", true)
    end

    it "returns early when span is nil" do
      job = HappyJob.new

      expect { job.send(:_sentry_set_span_data, nil, job, retry_count: 1) }.not_to raise_error
    end

    it "skips latency when enqueued_at is missing" do
      job = HappyJob.new
      span = instance_double(Sentry::Span, set_data: nil)

      job.send(:_sentry_set_span_data, span, job)

      expect(span).not_to have_received(:set_data).with("messaging.message.receive.latency", anything)
    end
  end

  describe ".setup" do
    it "returns when Sentry is not initialized" do
      allow(Sentry).to receive(:initialized?).and_return(false)
      allow(ActiveSupport).to receive(:on_load)

      described_class.setup

      expect(ActiveSupport).not_to have_received(:on_load)
    end

    it "enhances reporter and includes extensions when Rails and reporter are present", :aggregate_failures do
      perform_basic_setup
      allow(Sentry).to receive(:initialized?).and_return(true)

      stub_const("Rails", Module.new)
      Rails.singleton_class.define_method(:application) { nil }

      reporter = Class.new do
        def self.sentry_context(_job)
          {base: true}
        end
      end

      aj_extensions = Module.new
      stub_const("Sentry::Rails::ActiveJobExtensions", aj_extensions)
      stub_const("Sentry::Rails::ActiveJobExtensions::SentryReporter", reporter)

      job_class = Class.new(ActiveJob::Base)
      allow(ActiveSupport).to receive(:on_load).with(:active_job) do |&block|
        job_class.class_exec(&block)
      end

      span = instance_double(Sentry::Span, set_data: nil)
      allow(Sentry).to receive(:with_child_span).and_yield(span)
      allow(Time).to receive(:now).and_return(Time.at(1))

      described_class.setup

      # Reporter now merges GoodJob context
      job = HappyJob.new
      job.instance_variable_set(:@enqueued_at, Time.at(0))
      context = reporter.sentry_context(job)
      expect(context[:good_job]).to include(:queue_name, :executions)
      # GoodJob extensions included into Active Job
      expect(job_class.ancestors).to include(Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions)
    end
  end
end
