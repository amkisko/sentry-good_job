# frozen_string_literal: true

require "spec_helper"

RSpec.describe Sentry::GoodJob do
  describe "compatibility require path" do
    it "loads the nested path without error" do
      expect { require "sentry/good_job" }.not_to raise_error
    end

    it "defines Sentry::GoodJob after requiring" do
      require "sentry/good_job"
      expect(defined?(described_class)).to be_truthy
    end
  end
end
