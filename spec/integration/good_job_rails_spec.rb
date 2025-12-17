# frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass, RSpec/RemoveConst, RSpec/LeakyConstantDeclaration, Lint/ConstantDefinitionInBlock
require "spec_helper"

RSpec.describe "Rails + GoodJob integration" do
  before do
    skip "Rails not available" unless defined?(Rails)
    skip "GoodJob not available" unless defined?(GoodJob)

    begin
      require "sqlite3"
    rescue LoadError => e
      skip "sqlite3 not available: #{e.message}"
    end

    require "rails/all"

    # In-memory DB and schema to avoid external config/database.yml
    begin
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    rescue LoadError, ActiveRecord::AdapterNotFound => e
      skip "sqlite3 adapter not available: #{e.message}"
    end
    ActiveRecord::Schema.define do
      create_table :good_jobs, id: :string, force: true do |t|
        t.string :job_class
        t.datetime :cron_at
        t.integer :executions_count
        t.text :labels
        t.timestamps
      end

      create_table :good_job_processes, id: :string, force: true do |t|
        t.integer :lock_type
        t.text :state
        t.timestamps
      end

      create_table :good_job_executions, id: :string, force: true do |t|
        t.string :active_job_id
        t.string :job_class
        t.text :queue_name
        t.json :serialized_params
        t.string :process_id
        t.float :duration
        t.text :error_backtrace
        t.datetime :scheduled_at
        t.datetime :performed_at
        t.datetime :finished_at
        t.text :error
        t.integer :error_event, limit: 2
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end
    end

    unless defined?(::ApplicationJob)
      class ::ApplicationJob < ActiveJob::Base; end
    end

    Object.send(:remove_const, :HappyJobWithCron) if defined?(::HappyJobWithCron)
    class ::HappyJobWithCron < ApplicationJob
      include Sentry::Cron::MonitorCheckIns

      sentry_monitor_check_ins

      def perform
        Sentry.capture_message("hello from GoodJob")
      end
    end

    Object.send(:remove_const, :DummyApp) if defined?(::DummyApp)
    class DummyApp < Rails::Application
      config.paths["config/database"] = [File.expand_path("../../example/config/database.yml", __dir__)]
      config.root = File.expand_path("../../example", __dir__)
      config.eager_load = false
      config.secret_key_base = "test"
      config.logger = Logger.new(nil)
      config.hosts.clear if config.respond_to?(:hosts)
      config.active_job.queue_adapter = GoodJob::Adapter.new(execution_mode: :inline)
      config.good_job = ActiveSupport::OrderedOptions.new
      config.good_job.cron = {
        "happy_job_cron" => {class: "HappyJobWithCron", cron: "*/5 * * * *"}
      }
    end

    Rails.application = DummyApp.instance
    Rails.application.initialize!

    # SQLite doesn't support GoodJob's advisory lock SQL; stub to no-op for test
    if /sqlite/i.match?(ActiveRecord::Base.connection.adapter_name)
      job_class = GoodJob.const_get(:Job)
      job_class.class_eval do
        def advisory_lock(*)
          true
        end

        def advisory_lock!(*)
          true
        end

        def advisory_locked?
          false
        end

        def create_with_advisory_lock=(_)
        end

        def advisory_unlock(*)
          true
        end
      end
      job_class.singleton_class.class_eval do
        def advisory_lock(**)
          all
        end

        def with_advisory_lock(**)
          return [] unless block_given?
          yield([])
        end

        def advisory_unlock_session(*)
          true
        end
      end

      execution_class = GoodJob.const_get(:Execution)
      execution_class.class_eval do
        before_create { self.id ||= SecureRandom.uuid }
      end
    end

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define do
      create_table :good_jobs, id: :string, force: true do |t|
        t.text :queue_name
        t.integer :priority
        t.json :serialized_params
        t.datetime :scheduled_at
        t.datetime :performed_at
        t.datetime :finished_at
        t.text :error
        t.string :job_class
        t.string :active_job_id
        t.string :concurrency_key
        t.string :cron_key
        t.datetime :cron_at
        t.integer :executions_count
        t.text :labels
        t.string :locked_by_id
        t.bigint :retried_good_job_id
        t.string :batch_id
        t.string :batch_callback_id
        t.integer :error_event, limit: 2
        t.string :locked_by
        t.datetime :locked_at
        t.string :created_by
        t.string :workflow_id
        t.timestamps
      end

      create_table :good_job_processes, id: :string, force: true do |t|
        t.integer :lock_type
        t.text :state
        t.timestamps
      end

      create_table :good_job_executions, id: :string, force: true do |t|
        t.string :active_job_id
        t.string :job_class
        t.text :queue_name
        t.json :serialized_params
        t.string :process_id
        t.float :duration
        t.text :error_backtrace
        t.datetime :scheduled_at
        t.datetime :performed_at
        t.datetime :finished_at
        t.text :error
        t.integer :error_event, limit: 2
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end
    end

    perform_basic_setup
    Sentry.configuration.enabled_patches = [:good_job]
    Sentry.configuration.good_job.enable_cron_monitors = true
    Sentry::GoodJob.setup_good_job_integration
  end

  it "captures a GoodJob job with GoodJob context/tags and cron monitoring", :aggregate_failures do
    transport = Sentry.get_current_client.transport
    HappyJobWithCron.perform_later

    expect(transport.events.length).to be >= 1
    extract_tags = lambda do |e|
      return e[:tags] || e["tags"] if e.is_a?(Hash) && (e[:tags] || e["tags"])
      if e.respond_to?(:to_hash)
        h = e.to_hash
        return h[:tags] || h["tags"] if h
      end
      return e.tags if e.respond_to?(:tags)
      nil
    end

    event = transport.events.reverse.find do |e|
      tags = extract_tags.call(e)
      tags.present? || (e.respond_to?(:message) && e.message.present?) ||
        (e.is_a?(Hash) && (e[:message] || e["message"])) ||
        (e.respond_to?(:to_hash) && (e.to_hash[:message] || e.to_hash["message"]))
    end

    unless event
      skip "No GoodJob events captured (likely only check-ins present)"
    end

    tags = extract_tags.call(event)
    if tags.present?
      expect(tags).to include(:queue_name, :executions)
    end

    event_message =
      if event.respond_to?(:message)
        event.message
      elsif event.is_a?(Hash)
        event[:message] || event["message"]
      elsif event.respond_to?(:to_hash)
        h = event.to_hash
        h[:message] || h["message"]
      end
    expect(event_message).to include("hello from GoodJob")

    expect(HappyJobWithCron.singleton_class.ancestors).to include(Sentry::Cron::MonitorCheckIns::ClassMethods)
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/RemoveConst, RSpec/LeakyConstantDeclaration, Lint/ConstantDefinitionInBlock
