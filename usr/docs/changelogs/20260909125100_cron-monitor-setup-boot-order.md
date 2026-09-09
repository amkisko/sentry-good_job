Recorded 2026-09-09. Cron monitor setup now applies mixins during Railtie after-initialize, retries an empty schedule, accepts string keys, and warns when this process will not run Good Job cron.

## Participants

- amkisko

## Decisions

- Keep VERSION at 7.0.0 until the next release. Put operator-visible bullets under Unreleased in CHANGELOG.md.
- README states monitors are created or updated on the first check-in. enable_cron_monitors is not a substitute for config.good_job.enable_cron = true or good_job start --enable-cron.
- Callable schedules remain owned by Good Job and do not receive a static Sentry monitor configuration.
- Rails prepare repeats monitor setup after class reloads. Good Job CLI state remains unknown during Rails boot unless Rails config enables cron.

## Effects

- lib/sentry/good_job/cron_helpers.rb applies MonitorCheckIns inline. Empty cron logs and leaves setup retryable. String keys work. Reloader reset uses Integration.reset_setup_state!.
- spec/sentry/good_job/cron_helpers_spec.rb covers Railtie-timed mixin include, empty-hash retry, string keys, scheduler-disabled warning, and Reloader instance_exec reset.
- The focused specs also cover callable-schedule skip, indeterminate CLI state, and check-in reattachment to a replacement job class.

## Next

- Observed: bundle exec rubocop, 26 files, no offenses; polyrun parallel-rspec 5 workers exit 0; spec/integration pending because sqlite3 is not in the default Gemfile.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/sentry/good_job/cron_helpers_spec.rb, 42 examples, 0 failures.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rubocop, 26 files, no offenses.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec, 5 workers, exit 0.
- Observed after audit fixes: RBENV_VERSION=3.4.10 rbenv exec bundle exec rspec spec/integration, 1 pending because sqlite3 is not in the default Gemfile.
- Cut Unreleased into the next version heading at release.

## Source

- usr/docs/issues/20260909125100_cron-monitor-setup-boot-order.md
