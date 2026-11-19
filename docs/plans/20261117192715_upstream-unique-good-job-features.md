# Upstream unique Good Job features into sentry-rails

Design-only. Long-term goal: close the narrow gaps so `sentry-good_job` can deprecate after official `:good_job_cron` ships on Rubygems. Do not propose a parallel gem or re-home cron boot patching.

First step is not deprecation. Keep publishing this gem, and absorb the latest sentry-ruby / sentry-rails surface so hosts can upgrade the SDK without losing this gem's remaining value.

Related live work: `docs/issues/20261117191749_official-good-job-cron-overlap.md`.

## Step 0: absorb latest sentry-ruby (no gem deprecation)

Do this before upstream feature PRs and before any deprecation release.

Goals:

- Stay compatible with published `sentry-ruby` / `sentry-rails` 7.3.0 (includes official `:good_job_cron` and the job-extension ActiveJob path).
- Keep this gem's cron path, IGNORE defaults, and Good Job context helpers working. Do not add deprecation warnings or README "use official instead" cutover yet.

Work in this repo (Step 0 in progress / landing with 7.3 absorb):

- Gate `SentryReporter.sentry_context` monkeypatch: only when the method exists (7.2); skip on 7.3+.
- Prepend `RailsActiveJobExtension` onto `Sentry::Rails::ActiveJobExtension` when that class exists (7.3+).
- Keep enqueue-span fallback skipped when `record_producer_span` exists.
- Relock appraisal pins to `~> 7.3.0` within gemspec `sentry-ruby >= 7.0, < 8.0`.

Exit criteria: green tests on 7.3.0 appraisal cells; gem still presented as the supported Good Job add-on for hosts that need it.

## Scope (later upstream proposals)

Propose only durable gaps vs official sentry-rails master after #3199 / #3200:

1. Default exclude for Good Job concurrency and throttle exceeded errors.
2. Optional Good Job identity fields on error/context events (`labels`, legacy `concurrency_key`).

Out of scope for upstream (official already covers or supersedes):

- Boot-time `MonitorCheckIns` class patching from `config.good_job.cron`.
- Enqueue-span fallback when `record_producer_span` exists.
- Separate `config.good_job.enable_cron_monitors`.
- good_job 3.x cron support (official cron requires 4+).

## Already open: slugs

- Keep https://github.com/getsentry/sentry-ruby/pull/2750 as its own PR (slug readability / hashing).
- Rebase onto current `master` when needed; do not cobble IGNORE or context into it.
- Official `GoodJobCron` already uses `Sentry::Cron::Slug.from`, so #2750 helps that path after merge.
- Note in discussion if useful: Good Job cron keys are often already `snake_case`; #2750 matters most for class-derived slugs.

## Proposal A: concurrency / throttle IGNORE

Precedent: `Sentry::Sidekiq::IGNORE_DEFAULT` excludes expected retry-control exceptions.

Propose when `GoodJob` is loaded, append to excluded exceptions:

- `GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError`
- `GoodJob::ActiveJobExtensions::Concurrency::ThrottleExceededError`

Hosts can remove entries from `excluded_exceptions` if they want those events.

Shape: one slim PR into sentry-rails (or the Good Job registration path). Separate issue optional when the design is obvious from Sidekiq precedent. PR description still uses the RFC-style outline below.

Tests: excluded by default; re-enable works.

## Proposal B: labels / concurrency identity

Missing vs this gem today: nested Good Job fields that official messaging / ActiveJob context do not carry.

Open an issue before code. Proposed event shape:

```text
contexts.good_job.labels = [...]
contexts.good_job.concurrency_key = "..."
```

Rules for the issue and later PR:

- Put fields in `contexts` (or carefully scoped `extra`), not tags (labels are high-cardinality as tags).
- Duck-type with `respond_to?(:good_job_labels)` and `respond_to?(:good_job_concurrency_key)`; no hard `good_job` runtime dependency.
- Hook `ActiveJobExtension#apply_active_job_context` and/or `#active_job_error_data` on current master (job-extension path). Do not patch removed `SentryReporter.sentry_context`.
- Cite `sentry-good_job` ContextHelpers as prior art only.

Wait for maintainer signal, then one focused PR.

## Pull request standards

Upstream and in-repo PRs for this plan stay slim and reviewable.

Diff:

- One concern per PR. No cobbling (slug + IGNORE + context in one change).
- Smallest correct change. Prefer duck-typing and existing hooks over new layers.
- Match surrounding sentry-ruby / sentry-rails code: explicit fail-closed edges, no speculative API, tests that prove behavior.
- Follow Ruby core taste where it applies: clear names, stdlib before new deps, no clever indirection, let the host override defaults.
- Follow sentry-ruby principles: optional integrations via patches or detection, no hard dependency on `good_job` in sentry-rails, instrument and protocol words in public surface, changelog entry when the target repo requires it, conventional-commit PR title.

Description (RFC-style, even when there is no formal `rfcs/` file):

1. Summary: what this PR proposes, for whom.
2. Motivation: the gap in operator or implementer terms.
3. Specification: fields, defaults, fail modes, edge cases (the contract).
4. Guide-level note: what a host configures or sees after merge (short).
5. Drawbacks / alternatives: cost of adopting; cost of doing nothing; rejected shapes.
6. Prior art: Sidekiq IGNORE, official Good Job cron #3200, community gem helpers as evidence only.
7. Unresolved questions: only what must be settled before merge.
8. References: related GH issues, Linear IDs, PRs.

Omit empty sections. Keep the description factual; the diff stays the proof. Intent to deprecate the community gem belongs in motivation or drawbacks when relevant, not as marketing.

Optional follow-up comment on #3200 or a new tracking issue: remaining gaps after official cron.

## Sequence

1. Absorb latest sentry-ruby / sentry-rails in this gem (Step 0). No deprecation.
2. #2750 slugs (already open; rebase as needed). Can run in parallel with Step 0.
3. IGNORE PR upstream (after or beside Step 0; separate from #2750).
4. Context issue upstream, then PR after maintainer signal.
5. Wait for Rubygems release that includes #3200.
6. Only then: deprecate `sentry-good_job` with migration notes (config, slugs, dual-enable warning), then retire after the migration window.

## Opened upstream issues

- Slug underscore / format selection: https://github.com/getsentry/sentry-ruby/issues/3215 (PR #2750)
- Good Job concurrency/throttle IGNORE: https://github.com/getsentry/sentry-ruby/issues/3216
- Good Job labels / concurrency_key context: https://github.com/getsentry/sentry-ruby/issues/3217

## Source

- Live work: `docs/issues/20261117191749_official-good-job-cron-overlap.md`
- Slug PR: https://github.com/getsentry/sentry-ruby/pull/2750
- Official cron: https://github.com/getsentry/sentry-ruby/pull/3200
- Official GoodJob ActiveJob tests: https://github.com/getsentry/sentry-ruby/pull/3199
- Sidekiq IGNORE: `sentry-sidekiq/lib/sentry/sidekiq/configuration.rb`
- This gem prior art: `lib/sentry/good_job/configuration.rb`, `lib/sentry/good_job/context_helpers.rb`
