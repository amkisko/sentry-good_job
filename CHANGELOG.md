# Changelog

## 7.0.1 (2026-09-09)

- Warn when Good Job cron is empty while leaving setup available for a later reload
- Attach cron monitors when Rails finishes booting and reattach them when job classes reload
- Skip callable cron schedules with a warning instead of failing initialization
- Read string or symbol keys on cron job config
- Warn when Good Job cron is off, or when CLI options prevent confirming it during Rails boot
- Document that monitors are created or updated on the first check-in

## 7.0.0 (2026-09-07)

- BREAKING: Require sentry-ruby 7 (`>= 7.0`, `< 8.0`)
- Skip nested enqueue span when sentry-rails already records it
- Collect job arguments through `config.data_collection.queues`

## 6.2.1

- Relax dependencies to allow all current versions of sentry-ruby and good_job

## 6.2.0

### Features

- Initial release of sentry-good_job integration
- Automatic error capture for ActiveJob workers using Good Job
- Performance monitoring for job execution
- Automatic cron monitoring setup for scheduled jobs
- Context preservation and trace propagation
- Configurable error reporting options
- Rails integration with automatic setup

### Configuration Options

#### Good Job Specific Options
- `enable_cron_monitors`: Enable cron monitoring for scheduled jobs

#### ActiveJob Options (handled by sentry-rails)
- `config.rails.active_job_report_on_retry_error`: Only report errors after all retry attempts are exhausted
- `config.send_default_pii`: Include job arguments in error context

**Note**: The Good Job integration now leverages sentry-rails for core ActiveJob functionality, including trace propagation, user context preservation, and error reporting.

### Integration Features

- Seamless integration with Rails applications
- Automatic setup when Good Job integration is enabled
- Support for both manual and automatic cron monitoring
- Respects ActiveJob retry configuration
- Comprehensive error context and performance metrics
