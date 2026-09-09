Recorded 2026-09-09. Library gem. Cron monitor setup skipped empty hashes without a log, nested a second after-initialize hook, and read only symbol keys. Stay on main. Cut as 7.0.1.

## Participants

- amkisko

## Decisions

- Call mixin setup inline from the existing Railtie after-initialize path. Do not register another after-initialize callback per job.
- Treat nil and empty hash as no jobs yet. Log process, enable_cron, and execution_mode. Do not mark setup complete so a later filled schedule can still apply.
- Read class and cron from symbol or string keys.
- When enable_cron_monitors is on and this process will not run Good Job cron (enable_cron false and not a good_job start CLI), log that Sentry monitors appear after a job check-in.
- Reset setup state from the Reloader prepare hook through Integration.reset_setup_state! so instance_exec on Reloader cannot leave the class ivar set.
- Run cron monitor setup from the same prepare hook so reloaded job classes regain their check-in configuration.
- Treat Good Job CLI cron state as unknown during Rails boot when Rails config does not enable it. CLI options are applied after the application loads.
- Skip callable schedules with a warning because they cannot provide Sentry with a static crontab.

## Effects

- setup_monitoring_for_scheduled_jobs used cron_config.blank?. ActiveSupport treats {} as blank. That skip had no log.
- Each job registered Rails.application.config.after_initialize from inside the Railtie after-initialize block. Specs previously stubbed after_initialize and yielded. A Railtie-timed populated cron hash now includes MonitorCheckIns without that stub.
- job_config[:class] and job_config[:cron] skipped string-key entries with no warning.
- Reloader.to_prepare assigned @setup_completed = false in a block that Reloader instance_execs. The class ivar stayed true.
- A reset alone did not attach MonitorCheckIns to a replacement job class. The prepare hook now resets and repeats setup.
- A callable Good Job cron schedule raised NoMethodError from String parsing during monitor setup. It now leaves the Good Job schedule running without static Sentry monitor configuration.
- GoodJob::CLI.within_exe? identifies the executable, not whether --enable-cron was passed. Setup now reports that state as unknown instead of enabled.

## Next

- Observed: bundle exec rubocop, 26 files, no offenses.
- Observed: bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec, 5 workers, exit 0.
- Observed: bundle exec rspec spec/integration, 1 pending because sqlite3 is not in the default Gemfile (same as earlier runs).
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/sentry/good_job/cron_helpers_spec.rb, 42 examples, 0 failures.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rubocop, 26 files, no offenses.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec, 5 workers, exit 0.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/integration, 1 pending because sqlite3 is not in the default Gemfile.
- VERSION is 7.0.1. CHANGELOG.md heading is 7.0.1 dated 2026-09-09.
- Observed on prepare: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/sentry/good_job_spec.rb spec/sentry/good_job/cron_helpers_spec.rb, 50 examples, 0 failures.
- Observed on prepare: RBENV_VERSION=3.4.10 rbenv exec bundle exec rubocop, 26 files, no offenses.
- Observed on prepare: RBENV_VERSION=3.4.10 rbenv exec bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec, 5 workers, exit 0.
- Observed on prepare: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/integration, 1 pending because sqlite3 is not in the default Gemfile.
- Remaining: commit on main, then make release to publish. Do not gem push from this prepare pass.

## Source

- usr/docs/changelogs/20260909125100_cron-monitor-setup-boot-order.md
