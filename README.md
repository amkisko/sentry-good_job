<p align="center">
  <a href="https://sentry.io" target="_blank" align="center">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-logo-black.png" width="280">
  </a>
  <br>
</p>

# sentry-good_job, the Good Job integration for Sentry's Ruby client

---

[![Gem Version](https://img.shields.io/gem/v/sentry-good_job.svg)](https://rubygems.org/gems/sentry-good_job)
[![Build Status](https://github.com/amkisko/sentry-good_job/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/amkisko/sentry-good_job/actions/workflows/test.yml)
[![Coverage Status](https://img.shields.io/codecov/c/github/amkisko/sentry-good_job/main?logo=codecov)](https://app.codecov.io/github/amkisko/sentry-good_job)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=amkisko_sentry-good_job&metric=alert_status)](https://sonarcloud.io/project/overview?id=amkisko_sentry-good_job)
[![Gem](https://img.shields.io/gem/dt/sentry-good_job.svg)](https://rubygems.org/gems/sentry-good_job/)
[![SemVer](https://api.dependabot.com/badges/compatibility_score?dependency-name=sentry-good_job&package-manager=bundler&version-scheme=semver)](https://dependabot.com/compatibility-score.html?dependency-name=sentry-good_job&package-manager=bundler&version-scheme=semver)

Good Job integration for the [Sentry](https://sentry.io) Ruby SDK. Requires `sentry-ruby`, `sentry-rails`, and `good_job`.

## Install

```ruby
gem "sentry-ruby"
gem "sentry-rails"
gem "good_job"
gem "sentry-good_job"
```

With `:good_job` in `enabled_patches`, the railtie wires exception capture through sentry-rails, adds Good Job fields to Sentry context, and can register cron monitors from `config.good_job.cron`.

## Features

- Exception capture for ActiveJob workers that use Good Job (via sentry-rails)
- Job execution spans and queue latency when this gem records the enqueue span
- Cron monitor registration from Good Job scheduled jobs
- User context and trace propagation from sentry-rails
- Reporting after retries controlled by sentry-rails ActiveJob options

## Configuration

```ruby
Sentry.init do |config|
  config.dsn = "your-dsn-here"

  # Good Job specific configuration
  config.good_job.enable_cron_monitors = true

  # ActiveJob configuration (handled by sentry-rails)
  config.rails.active_job_report_on_retry_error = false
  config.data_collection.queues = false

  # Optional: Configure logging for debugging
  config.sdk_logger = Rails.logger
end
```

### Configuration Options

#### Good Job Specific Options

- `enable_cron_monitors` (default: `true`): Register cron monitors for scheduled jobs

#### ActiveJob Options (handled by sentry-rails)

- `config.rails.active_job_report_on_retry_error` (default: `false`): Report errors only after retries are exhausted
- `config.data_collection.queues` (default: `true`): Include job arguments in error context (sensitive data risk)
- `config.sdk_logger` (default: `nil`): SDK logger for setup and cron warnings

Core ActiveJob capture, trace propagation, and user context come from sentry-rails. This gem adds Good Job cron monitors and extra job context (`queue_name`, `executions`, `enqueued_at`, `priority`).

## Usage

### Automatic Setup

Once installed and enabled, the integration:

1. Captures exceptions from ActiveJob workers through sentry-rails
2. Records performance spans for job execution; adds queue latency on this gem's enqueue span fallback
3. Registers cron monitors for scheduled jobs from Good Job config
4. Keeps user context and trace headers from sentry-rails
5. Merges Good Job context (`queue_name`, `executions`, `priority`, `enqueued_at`) into `sentry_context`

`ContextHelpers.add_tags` is available for hosts that set tags themselves. Setup does not call it; sentry-rails has no tags enhancement hook.

### Cron Monitoring

Cron monitors follow your Good Job schedule:

```ruby
# config/application.rb
config.good_job.cron = {
  "my_scheduled_job" => {
    class: "MyScheduledJob",
    cron: "0 * * * *" # Every hour
  }
}
```

Sentry creates or updates monitors on the first check-in. `enable_cron_monitors` registers check-ins on job classes. It is not a substitute for `config.good_job.enable_cron = true` or `good_job start --enable-cron`.

Callable Good Job cron schedules still run. This integration skips Sentry monitor configuration for them because they have no static crontab.

Manual cron monitoring:

```ruby
class MyScheduledJob < ApplicationJob
  include Sentry::Cron::MonitorCheckIns

  sentry_monitor_check_ins(
    slug: "my_scheduled_job",
    monitor_config: Sentry::Cron::MonitorConfig.from_crontab("0 * * * *", timezone: "UTC")
  )
end
```

### Custom Error Handling

Reporting follows ActiveJob retries and sentry-rails settings:

```ruby
class MyJob < ApplicationJob
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    # Reported after 3 attempts when active_job_report_on_retry_error is true
    raise "Something went wrong"
  end
end
```

### Debugging and Logging

Use `Sentry.configuration.sdk_logger`:

```ruby
Sentry.init do |config|
  config.dsn = "your-dsn-here"

  config.sdk_logger = Logger.new($stdout)
  config.sdk_logger.level = Logger::DEBUG

  # Or use Rails logger with debug level
  # config.sdk_logger = Rails.logger
  # config.sdk_logger.level = Logger::DEBUG
end
```

Log levels:

- INFO: Integration setup, cron monitoring configuration, job monitoring setup
- WARN: Configuration issues, missing job classes, cron parsing errors
- DEBUG: Detailed execution flow when debug level is enabled

Typical messages cover cron monitor setup, missing job classes, cron parse failures, and integration initialization. Job execute start/complete and capture decisions come from sentry-rails when that logger is shared.

## Performance Monitoring

When performance monitoring is enabled:

- Job execution time (sentry-rails / Sentry spans)
- Queue latency on this gem's enqueue-span fallback (skipped when sentry-rails `record_producer_span` is present)
- Retry counts
- Good Job context fields: queue name, executions, priority

## Error Context

Merged into error reports:

- Job class name, job ID, locale, scheduled_at (sentry-rails)
- Queue name, execution count, priority, enqueued_at (this gem under `good_job`)
- Job arguments when `config.data_collection.queues` is enabled

## Compatibility

- Ruby 3.4+
- Good Job 3.x and 4.x
- Sentry Ruby SDK 7.x

## Contributing

See [contributing guidelines](./CONTRIBUTING.md).

## Links

- [GitHub](https://github.com/amkisko/sentry-good_job)
- [GitLab](https://gitlab.com/amkisko/sentry-good_job)
- [RubyGems](https://rubygems.org/gems/sentry-good_job)
- [Versions Atom](https://rubygems.org/gems/sentry-good_job/versions.atom) (feed id `10143542922948`)
- [libraries.io](https://libraries.io/rubygems/sentry-good_job)
- [Deps.dev](https://deps.dev/rubygems/sentry-good_job)
- [SonarCloud](https://sonarcloud.io/project/overview?id=amkisko_sentry-good_job)
- [Snyk](https://snyk.io/test/github/amkisko/sentry-good_job)
- [Codecov](https://app.codecov.io/github/amkisko/sentry-good_job)
- [OpenSSF Scorecard](https://scorecard.dev/viewer/?uri=github.com/amkisko/sentry-good_job)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE.txt) file for details.
