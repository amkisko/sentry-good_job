# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Sentry GoodJob Integration", type: :job do
  before do
    perform_basic_setup
    # Use :inline adapter to get real GoodJob behavior with immediate execution
    # This provides actual GoodJob attributes like queue_name, executions, priority, etc.
    ActiveJob::Base.queue_adapter = :inline

    # Set up the GoodJob integration
    Sentry::GoodJob.setup_good_job_integration

    stub_const("TestGoodJob", test_good_job_class)
    stub_const("FailingGoodJob", failing_good_job_class)
    stub_const("GoodJobWithContext", good_job_with_context_class)
    stub_const("AppUserJob", app_user_job_class)
    stub_const("AppDataJob", app_data_job_class)
  end

  let(:transport) do
    Sentry.get_current_client.transport
  end

  let(:app_user_job_class) do
    Class.new(ApplicationJob) do
      def perform(user_id, action)
        # Simulate user-related job processing
        Sentry.set_user(id: user_id)
        Sentry.set_tags(job_type: "user_processing", action: action)

        # Simulate some work
        sleep(0.01) if action == "slow_processing"

        raise StandardError, "User processing failed: #{action}" if action == "fail"

        "User #{user_id} processed for #{action}"
      end
    end
  end

  let(:app_data_job_class) do
    Class.new(ApplicationJob) do
      def perform(data, count)
        # Simulate data processing job
        Sentry.set_tags(job_type: "data_processing", data_size: data.length, count: count)

        # Simulate some work
        sleep(0.01) if count > 2

        raise StandardError, "Data processing failed: #{data}" if data == "fail"

        "Processed #{count} items of data: #{data}"
      end
    end
  end

  let(:test_good_job_class) do
    Class.new(ApplicationJob) do
      def perform(message)
        "Processed: #{message}"
      end
    end
  end

  let(:failing_good_job_class) do
    Class.new(ApplicationJob) do
      def perform(message)
        raise StandardError, "Job failed: #{message}"
      end
    end
  end

  let(:good_job_with_context_class) do
    Class.new(ApplicationJob) do
      def perform(user_id)
        Sentry.set_user(id: user_id)
        Sentry.set_tags(job_type: "context_test")
        raise StandardError, "Context test error"
      end
    end
  end

  describe "GoodJob extensions integration" do
    it "successfully executes jobs without errors" do
      result = TestGoodJob.perform_now("test message")
      expect([result, transport.events.size]).to eq(["Processed: test message", 0])
    end

    it "verifies GoodJob extensions are properly included" do
      # Test that the GoodJob extensions are working by checking that
      # the GoodJobExtensions module is included in ActiveJob::Base
      expect(ActiveJob::Base.ancestors).to include(Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions)
    end

    it "verifies GoodJob-specific methods are available" do
      # Test that the GoodJob-specific methods are available
      job = TestGoodJob.new("test")

      # The GoodJob extensions should add the _sentry_set_span_data method
      # Note: This method is private, so we test it indirectly
      expect(job.class.private_method_defined?(:_sentry_set_span_data)).to be true
    end

    it "verifies GoodJob context helpers work correctly" do
      # Test that the GoodJob context helpers work correctly
      job = TestGoodJob.new("test")

      # Test the enhance_sentry_context method
      base_context = {"active_job" => "TestGoodJob"}
      enhanced_context = Sentry::GoodJob::ActiveJobExtensions.enhance_sentry_context(job, base_context)

      expect(enhanced_context).to match(hash_including(good_job: hash_including(:queue_name, :executions)))
    end
  end

  describe "integration setup" do
    it "sets up GoodJob extensions when integration is enabled" do
      # This test verifies that the integration properly sets up the extensions
      # by checking that the GoodJobExtensions module is included in ActiveJob::Base
      expect(ActiveJob::Base.ancestors).to include(Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions)
    end

    it "verifies GoodJob integration is properly configured" do
      expect(Sentry.configuration.good_job).to have_attributes(enable_cron_monitors: true)
    end
  end

  describe "GoodJob extensions functionality" do
    it "verifies GoodJob extensions work with different job types" do
      # Test that the GoodJob extensions work with different job types
      user_job = AppUserJob.new("user1", "update")
      data_job = AppDataJob.new("test", 3)

      # Both jobs should have the GoodJob extensions
      aggregate_failures do
        expect(user_job.class.ancestors).to include(Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions)
        expect(data_job.class.ancestors).to include(Sentry::GoodJob::ActiveJobExtensions::GoodJobExtensions)
      end
    end

    it "verifies GoodJob context enhancement works correctly" do
      # Test that the GoodJob context enhancement works correctly
      job = AppUserJob.new("user1", "update")

      # Test the enhance_sentry_context method
      base_context = {"active_job" => "AppUserJob"}
      enhanced_context = Sentry::GoodJob::ActiveJobExtensions.enhance_sentry_context(job, base_context)

      # The enhanced context should include GoodJob-specific data
      aggregate_failures do
        expect(enhanced_context).to include(:good_job)
        expect(enhanced_context[:good_job]).to include(:queue_name, :executions)
        expect(enhanced_context[:good_job][:queue_name]).to eq("default")
        expect(enhanced_context[:good_job][:executions]).to eq(0)
      end
    end

    it "verifies GoodJob span data methods work correctly" do
      # Test that the GoodJob span data methods work correctly
      job = AppUserJob.new("user1", "update")

      # Create a mock span that expects the set_data calls
      span = double("span")
      allow(span).to receive(:set_data)

      aggregate_failures do
        # Test that the private method exists and can be called via send
        expect { job.send(:_sentry_set_span_data, span, job) }.not_to raise_error

        # Test that the method is properly defined
        expect(job.class.private_method_defined?(:_sentry_set_span_data)).to be true
      end
    end
  end
end
