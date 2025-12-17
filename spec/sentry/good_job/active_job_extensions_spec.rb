# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob::ActiveJobExtensions do
  before do
    perform_basic_setup
    described_class.setup
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
  end
end
