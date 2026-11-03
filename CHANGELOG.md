# Changelog

## 7.0.3 (2026-11-03)

- Remove unwired `ActiveJobExtensions.enhance_sentry_tags` (no sentry-rails tags hook)
- Keep `ContextHelpers.add_tags` as a manual helper for host apps
- Drop the futile `skippable_job_adapters` example that never asserted production behavior
- Simplify `_sentry_set_span_data` by removing an unreachable `super` branch after Concern include on `ActiveJob::Base`
- Add `sqlite3` to the root Gemfile so `spec/integration` runs under the default bundle

## 7.0.2 (2026-10-30)

- Fail closed when release confirmation input reaches EOF
- Require a matching `CHANGELOG.md` version heading before `gem push`

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

- Initial Good Job integration for Sentry Ruby
- Error capture for ActiveJob workers using Good Job
- Job execution spans and cron monitor setup for scheduled jobs
- Context and trace propagation via sentry-rails
- Configurable error reporting through sentry-rails ActiveJob options
