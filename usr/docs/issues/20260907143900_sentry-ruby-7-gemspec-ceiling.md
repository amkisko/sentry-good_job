Recorded 2026-09-07. Library gem. Claims audit, dependency recon, and sentry-ruby 7 support. No branch switch. No release. Later the same day the plan changed from a 6.3.0 dual-range release to sentry-good_job 7.0.0 requiring sentry-ruby 7 only.

## Participants

- amkisko

## Decisions

- Align this gem with sentry-ruby 7. Release sentry-good_job 7.0.0 with sentry-ruby >= 7.0, < 8.0.
- Keep published 6.2.1 as the last 6-only line. Do not dual-range 6.x and 7.x on one gem version.
- At enqueue time, skip this gem's queue.publish span when sentry-rails already records it through SentryReporter.record_producer_span.
- Treat ActiveJob exception capture as sentry-rails work. This gem's unique 7.x value is Good Job cron check-ins plus extra job context.
- Job arguments on 7.x use config.data_collection.queues. send_default_pii is deprecated in sentry-ruby 7.0.0.

## Effects

- Published 6.2.1 and GitHub main gemspec both required sentry-ruby >= 6.0, < 7.0. RubyGems 6.2.1 created 2025-12-17. Runtime deps were good_job >= 3.0, < 5.0 and sentry-ruby >= 6.0, < 7.0.
- sentry-ruby 7.0.0 and sentry-rails 7.0.0 landed on RubyGems 2026-09-01. sentry-rails 7.0.0 requires sentry-ruby ~> 7.0.0. Official siblings use ~> 7.0.0.
- amkisko/sentry-ruby main VERSION is 7.0.0 as of 2026-09-02. That tree is a local copy of the SDK, not the RubyGems publisher of 7.0.0.
- Commit 821cea68950890768492bd5d5c9c00a694cfcd70 exists on amkisko/sentry-ruby. Message: Merge remote-tracking branch upstream/master. Date 2026-09-02. Pairing that SHA with gem version 6.2.0 is not supported by that commit.
- This repo Gemfile.lock pinned sentry-ruby 6.2.0 before the 7.0.0 work. CI appraisals ruby34 and rails8 inherited the same < 7.0 ceiling.
- APIs this gem uses still exist on sentry-ruby 7.0.0: Integrable, register_integration, enabled_patches, add_post_initialization_callback, sdk_logger, excluded_exceptions, Cron::MonitorCheckIns, Cron::MonitorConfig.from_crontab, DummyTransport, TestHelper.
- sentry-rails 7.0.0 still defines Sentry::Rails::ActiveJobExtensions::SentryReporter.sentry_context, so the class_eval enhance still binds.
- sentry-rails 6.7.0 and 7.0.0 already add around_enqueue via record_producer_span (op queue.publish) and set messaging.message.receive.latency. A ceiling-only 7.x bump would duplicate enqueue spans.
- README Compatibility was stale: Ruby 2.4+, Rails 5.2+, Good Job 4.x, Sentry Ruby SDK 6.x. Gemspec already required Ruby >= 3.4 and good_job >= 3.0, < 5.0.

## Next

- make test on the default Gemfile: rubocop 26 files no offenses; polyrun parallel-rspec 5 workers exit 0; spec/integration pending because sqlite3 is not in the default Gemfile.
- BUNDLE_GEMFILE=gemfiles/ruby34.gemfile: 21 examples, 0 failures.
- BUNDLE_GEMFILE=gemfiles/rails8.gemfile: 14 examples, 0 failures, including spec/integration.
- After CI green, run make release. Consumers on sentry-ruby 6 stay on 6.2.1. Consumers on sentry-ruby 7 restore gem sentry-good_job, config.enabled_patches += [:good_job], and config.good_job.enable_cron_monitors = true.
