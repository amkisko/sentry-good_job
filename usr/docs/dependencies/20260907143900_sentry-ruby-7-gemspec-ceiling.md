Recorded 2026-09-07 during the sentry-ruby 7 compatibility review. This is a consumer-range defect in this gem, not a behavioral bug in sentry-ruby. Later the same day the plan changed from 6.3.0 dual-range to sentry-good_job 7.0.0 requiring sentry-ruby 7 only.

## Dependency

- Package: sentry-ruby (direct runtime of sentry-good_job).
- Manifest: sentry-good_job.gemspec add_dependency sentry-ruby >= 7.0, < 8.0 (was >= 6.0, < 7.0 on 6.2.1).
- Lockfile: Gemfile.lock and gemfiles/*.gemfile.lock pinned sentry-ruby 6.2.0 before this change.
- Registry latest: sentry-ruby 7.0.0 published 2026-09-01 by Sentry Team from getsentry/sentry-ruby. sentry-rails 7.0.0 requires sentry-ruby ~> 7.0.0.
- Related: good_job >= 3.0, < 5.0 is unchanged.

## Symptom

A Gemfile that lists sentry-good_job 6.2.1 cannot lock sentry-ruby 7.x or sentry-rails 7.x. Bundler must satisfy < 7.0. Automatic Good Job cron monitors from this gem stay unavailable until a 7.x release of this gem.

## Evidence

- RubyGems 6.2.1 runtime dependency sentry-ruby >= 6.0, < 7.0.
- GitHub main gemspec still had that floor before this work.
- sentry-ruby 7.0.0 still exposes Integrable, enabled_patches, Cron::MonitorCheckIns, and MonitorConfig.from_crontab. sentry-rails 7.0.0 still exposes SentryReporter.sentry_context.
- sentry-rails 6.7.0 and 7.0.0 already register around_enqueue queue.publish. A ceiling-only bump would nest a second publish span from GoodJobExtensions.

## Suggested fix

- Release sentry-good_job 7.0.0 with sentry-ruby >= 7.0, < 8.0.
- Pin CI appraisals to sentry-ruby ~> 7.0.0 and sentry-rails ~> 7.0.0 on the rails8 cell.
- At enqueue time, skip this gem's queue.publish span when SentryReporter.record_producer_span exists.
- Keep 6.2.1 for apps that stay on sentry-ruby 6.

## Next

- make test on the default Gemfile: rubocop clean; polyrun parallel-rspec exit 0; integration pending without sqlite3.
- Restore the gem in consuming apps after the 7.0.0 release.
