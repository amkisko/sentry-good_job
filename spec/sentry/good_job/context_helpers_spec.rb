# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob::ContextHelpers do
  let(:base_context) { {existing: "value"} }
  let(:base_tags) { {existing: "tag"} }

  let(:job_with_attributes) do
    Struct.new(:queue_name, :executions, :enqueued_at, :priority).new(
      "default",
      2,
      Time.utc(2023, 1, 1, 0, 0, 0),
      10
    )
  end

  let(:job_without_attributes) { double("JobWithoutAttrs") }

  describe ".add_context" do
    it "merges GoodJob-specific context when attributes are present", :aggregate_failures do
      result = described_class.add_context(job_with_attributes, base_context)

      expect(result).to include(:good_job)
      expect(result[:good_job]).to include(
        queue_name: "default",
        executions: 2,
        enqueued_at: Time.utc(2023, 1, 1, 0, 0, 0),
        priority: 10
      )
      expect(result[:existing]).to eq("value")
    end

    it "returns the base context untouched when attributes are missing" do
      result = described_class.add_context(job_without_attributes, base_context)

      expect(result).to eq(base_context)
    end
  end

  describe ".add_tags" do
    it "merges GoodJob-specific tags when attributes are present", :aggregate_failures do
      result = described_class.add_tags(job_with_attributes, base_tags)

      expect(result).to include(
        queue_name: "default",
        executions: 2,
        priority: 10
      )
      expect(result[:existing]).to eq("tag")
    end

    it "returns the base tags untouched when attributes are missing" do
      result = described_class.add_tags(job_without_attributes, base_tags)

      expect(result).to eq(base_tags)
    end
  end
end
