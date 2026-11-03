# Engineering and prose audit before 7.0.3 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main after published 7.0.2. Include unwired tags helper removal, futile skippable_job_adapters example, latency assertion after super, README and changelog prose, ASCII punctuation in spec docs. Leave tag and RubyGems publish to make release after commit.

## Effects

Pipeline: Railtie after_initialize -> ActiveJobExtensions / CronHelpers -> Sentry SDK / cron check-in registration. Boundary mode covered Sentry as external API and Good Job cron config as command source. Resource and identification modes: cold-require observation only; no new person identifiers in gem logs. Queue, worker, learned-system, and physical plant modes skipped where absent from this library.

Ranked fixes applied:

1. Remove `ActiveJobExtensions.enhance_sentry_tags` after confirming sentry-rails exposes `sentry_context` but no tags enhancement hook (high confidence, observed).
2. Document `ContextHelpers.add_tags` as a manual host helper (high confidence, observed).
3. Drop futile `skippable_job_adapters` example that only asserted Array (high confidence, observed).
4. Collapse duplicate cron-setup examples in `good_job_spec` (medium confidence, observed).
5. Remove unreachable `_sentry_set_span_data` `super` branch: after Concern include on `ActiveJob::Base`, a class override shadows the helper and Concern blocks prepend (high confidence, observed in session).
6. README and CHANGELOG prose pass; ASCII dashes in `spec/README.md` and junit formatter comment.
7. Add `sqlite3` (>= 2.9.6) to the root Gemfile so default-bundle `spec/integration` runs (was pending forever).

Deferred:

- Class-ivar races on `@setup_completed` / `@reporter_enhanced` under threaded boot (low; Rails boot is typically single-threaded).
- `add_monitoring_to_job` default hourly crontab when cron is omitted (low footgun; document or require cron later).

Checks observed in this session:

- bundle exec rubocop on touched Ruby files: 5 files, no offenses.
- POLYRUN_COVERAGE=1 bundle exec polyrun parallel-rspec --workers 5 --merge-failures: exit 0; coverage/merged-summary.txt 98.09% lines (205 / 209) across 6 files.
- bundle exec rspec spec/integration: 1 example, 0 failures (after root Gemfile sqlite3).
- gem build sentry-good_job.gemspec and Gem::Package#verify for 7.0.3: ok.
- Cold require under bundler: wall 0.355 s, RSS after 52,887,552 bytes, RSS delta 36,618,240 bytes. Single-machine observation, not a release budget.

## Next

Commit, then make release.

## Source

- docs/issues/20261103171803_engineering-prose-release-audit.md
- docs/issues/20261030113102_unwired-enhance-sentry-tags.md
- CHANGELOG.md section 7.0.3 (2026-11-03)
- Prior pass: docs/reviews/20261030113102_engineering-audit-release-preparation.md
