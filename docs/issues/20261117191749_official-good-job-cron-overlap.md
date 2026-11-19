# Official sentry-rails Good Job support vs sentry-good_job

## Participants

- Andrei Makarov

## Decisions

- Treat getsentry/sentry-ruby `Sentry::Rails::GoodJobCron` (`:good_job_cron` patch, PR #3200, merged 2026-11-16, not in released 7.2.0) as the intended long-term cron path for Good Job 4+.
- Treat sentry-rails ActiveJob / job-extension path (including GoodJob adapter coverage from PR #3199) as the intended path for exception capture, tracing, and queue spans. Do not keep a parallel gem for those.
- Remaining durable value in this gem is narrow: concurrency/throttle `IGNORE_DEFAULT`, nested `good_job` error context (`labels`, legacy `concurrency_key`). Do not keep publishing the whole gem only for those unless they are upstreamed into sentry-rails first.
- Temporary bridge value until #3200 ships on Rubygems: cron on released `sentry-rails` 7.2.0, and declared `good_job` 3.x support (official cron requires 4+).
- First keep publishing this gem and absorb latest sentry-ruby / sentry-rails (including post-7.2.0 master API shifts). No deprecation in that step.
- Plan to deprecate and eventually retire `sentry-good_job` only after that absorb work and after an official sentry-rails release that includes `#3200`, with a migration note for config and monitor slugs.
- Do not recommend running `:good_job` (this gem) and `:good_job_cron` (official) together without an explicit dual-run audit.

## Effects

- Upstream on `master` (local merge of `upstream/master` at `45e36ca7`):
  - Cron check-ins: `sentry-rails/lib/sentry/rails/good_job_cron.rb`, opt-in via `config.enabled_patches << :good_job_cron`, exclude via `config.rails.good_job_exclude_cron_jobs`, requires `good_job >= 4.0`.
  - ActiveJob on GoodJob: shared backend harness + `spec/active_job/good_job_spec.rb` (errors, tracing, `messaging.system` => `good_job`).
  - Parallel pattern already exists for Solid Queue: `:solid_queue_recurring`.
- This gem still unique today (durable gaps vs official):
  - `IGNORE_DEFAULT` for `GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError` and `ThrottleExceededError` (official does not exclude them).
  - Nested `good_job` error context fields `labels` and legacy `concurrency_key` (official puts queue / executions / latency on messaging and ActiveJob fields, not these).
- This gem still useful as a bridge only:
  - Boot-time cron via `MonitorCheckIns` from `config.good_job.cron` on published SDK versions that lack `:good_job_cron`.
  - Declared `good_job` 3.x support (`>= 3.0`, `< 6.0`); official cron patch warns below 4.0.
- Overlap / redundant surface once official ships:
  - README features that are pure sentry-rails (exception capture, user context, trace propagation, retry reporting, producer spans when `record_producer_span` exists).
  - Enqueue-span fallback in `ActiveJobExtensions` is skipped whenever sentry-rails registers `record_producer_span`.
  - Cron path itself: official event-based check-ins supersede boot-time class patching.
- Breakage risk against post-7.2.0 sentry-rails master: job-extension refactor (#3130 and related commits) removes `SentryReporter.sentry_context`. This gem's `alias_method :original_sentry_context, :sentry_context` will fail at setup against that API. Confirmed present on tag `7.2.0`, absent on current `sentry-rails/lib/sentry/rails/active_job.rb` on master.
- Slug migration risk: this gem uses `underscore` + strip trailing `_job`; official uses `Sentry::Cron::Slug.from(cron_key)` (downcase, non-alnum to `-`, max length). Existing monitors may not match after switch.
- Official skips automatic cron check-ins when the job class already includes `Sentry::Cron::MonitorCheckIns::Patch`, so a host that keeps this gem's class patch will keep this gem's check-in path for those jobs.
- Rubygems: `sentry-ruby` / `sentry-rails` 7.3.0 published and includes #3200. This gem absorb work lands on branch `patch/absorb-sentry-ruby-7-3` (gate `sentry_context`, register `:good_job` ActiveJob extension, appraisal `~> 7.3.0`).

## Next

- Finish/merge Step 0 absorb (`patch/absorb-sentry-ruby-7-3`); no deprecation in that release.
- Then follow the plan: keep #2750 / #3215 separate; open IGNORE PR for #3216; context PR after signal on #3217; deprecate this gem only after migration guidance for hosts on official `:good_job_cron`.
- If durable gaps are not upstreamed before deprecation ends, accept that retirement drops them.
- After migration window: yank guidance to remove the gem; archive or mark the repo read-only.

## Source

- Plan: `docs/plans/20261117192715_upstream-unique-good-job-features.md`
- Slug PR: https://github.com/getsentry/sentry-ruby/pull/2750
- Upstream issues: https://github.com/getsentry/sentry-ruby/issues/3215 , https://github.com/getsentry/sentry-ruby/issues/3216 , https://github.com/getsentry/sentry-ruby/issues/3217
- Upstream cron PR: https://github.com/getsentry/sentry-ruby/pull/3200
- Upstream test infra PR: https://github.com/getsentry/sentry-ruby/pull/3199
- Local upstream files: `sentry-rails/lib/sentry/rails/good_job_cron.rb`, `sentry-rails/spec/active_job/good_job_spec.rb`, `sentry-rails/spec/active_job/good_job_cron_spec.rb`
- This gem: `lib/sentry-good_job.rb`, `lib/sentry/good_job/cron_helpers.rb`, `lib/sentry/good_job/active_job_extensions.rb`, `lib/sentry/good_job/context_helpers.rb`, `lib/sentry/good_job/configuration.rb`, `README.md`
- Rubygems: https://rubygems.org/gems/sentry-good_job , https://rubygems.org/gems/sentry-rails
