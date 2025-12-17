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

  describe "Railtie auto setup" do
    it "invokes setup_good_job_integration when Rails Railtie is present" do
      perform_basic_setup
      Sentry.configuration.enabled_patches = [:good_job]
      stub_const("Sentry::Rails", Module.new)
      allow(Sentry).to receive(:initialized?).and_return(true)

      stub_const("Rails", Module.new)
      railtie_config = double("RailtieConfig", after_initialize: nil)
      stub_const(
        "Rails::Railtie",
        Class.new do
          def self.config
            @config ||= double("config")
          end
        end
      )
      allow(Rails::Railtie).to receive(:config).and_return(railtie_config)
      allow(railtie_config).to receive(:after_initialize).and_yield
      Rails.singleton_class.define_method(:application) { nil }

      allow(described_class).to receive(:setup_good_job_integration)

      described_class.send(:remove_const, :Railtie) if described_class.const_defined?(:Railtie, false) # rubocop:disable RSpec/RemoveConst
      load File.expand_path("../../lib/sentry-good_job.rb", __dir__)

      expect(described_class).to have_received(:setup_good_job_integration)
    end
  end
end
