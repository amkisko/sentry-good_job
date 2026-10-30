Iterative engineering audit and 7.0.2 release preparation on 2026-10-30.

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Ship 7.0.2 as a maintainer-tooling patch: EOF-safe release confirmation, changelog version gate, cleaner git/tag push.
- Deduplicate GoodJob context and tags helpers through `ContextHelpers`.
- Defer wiring or deleting unwired `enhance_sentry_tags` to a later issue.
- Skip product-surface, privacy product UI, learned-systems, and lineage modes: this tree is a library gem with no person-facing presentation of its own.
- Run boundary mode for Sentry as the external API and Good Job cron config as the command source. Run resource, trace, security (supply-chain companion), contract, and observability modes on the library and release path.

## Effects

Audit pipeline map:

1. ingress: Rails Railtie `after_initialize` and `enabled_patches` including `:good_job`
2. app logic: ActiveJob context enhance, optional enqueue span fallback, cron monitor attach
3. cache: none in this gem
4. database: none owned here; Good Job tables stay upstream
5. queue / worker: enqueue span skipped when sentry-rails `record_producer_span` exists (intentional since 7.0.0)
6. external API: Sentry SDK capture and cron monitor check-in registration
7. egress: Sentry events and monitor config created in the host app process

Findings ranked by danger, certainty, impact, fix cost:

1. Severity: medium. Confidence: high. Location: `usr/bin/release.rb` confirmation via `$stdin.gets`. Why it matters: EOF used to call `.chomp` on nil and crash mid-release. Evidence kind: observed in prior tree; fixed by `ReleaseVersionCheck.confirmation_accepted?`. Smallest fix: done in 7.0.2.

2. Severity: medium. Confidence: high. Location: release path without changelog heading check. Why it matters: version bump can leave `CHANGELOG.md` stale and still push. Evidence kind: observed absence before this patch. Smallest fix: `require_changelog_version!` plus specs. Done in 7.0.2.

3. Severity: low. Confidence: high. Location: `ActiveJobExtensions.enhance_sentry_tags`. Why it matters: tested helper never reached from `setup`; gives false confidence that tags ship. Evidence kind: observed (grep shows no production call). Kind split: missing wiring on the setup path; futile confidence from unit-only coverage. Smallest fix: document or delete later. Tracked in `docs/issues/20261030113102_unwired-enhance-sentry-tags.md`.

4. Severity: low. Confidence: high. Location: duplicated context/tag builders in `ContextHelpers` and `ActiveJobExtensions`. Why it matters: two owners for one shape. Evidence kind: observed. Smallest fix: delegate; done in this pass.

5. Severity: low. Confidence: medium. Location: resource budgets for cold require. Why it matters: prior pass measured one cold require (about 0.64 CPU s, about 55 MB peak RSS) without a named release ceiling. Evidence kind: observed prior number; inference that it remains representative until re-measured. Smallest fix: re-run require bench at release and record under Effects when numbers move.

Boundary mode: host app commands cron monitor attach; Sentry reports monitor and event state. Intended schedule lives in Good Job cron config; commanded attach happens at boot/reload; reported monitors appear after first check-in (already documented). No physical actuator. Partial Sentry outage leaves jobs running; monitors may be missing until a later check-in.

Resource mode: executable library and release scripts. No house CPU/RSS/gem-size ceiling documented beyond the prior cold-require observation.

Trace mode: this gem forwards queue name, executions, enqueued_at, priority into Sentry context. Job arguments stay behind sentry-rails `config.data_collection.queues` / PII settings. Release checker User-Agent is `release-version-check` only.

Security / supply-chain: release still needs a clean tree, human confirmation, and local credentials for `gem push`. Changelog gate and EOF fail-closed harden the human step. Tag push now sends `HEAD` and the tag together.

Contract mode: public surface is the gem API and Sentry/Good Job integration contracts. 7.0.2 does not change runtime job contracts.

Observability mode: uses host Sentry SDK logger and cron monitors; no separate process.

Modes skipped: product-surface (no UI), privacy product UI (no first-party person UI; PII policy stays in sentry-rails), learned-systems (none), lineage of business numbers (none beyond VERSION).

Validation observed in this session:

- `bundle exec rubocop`: 28 files, no offenses.
- `bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec`: exit 0.
- `bundle exec rspec spec/integration`: 1 pending (`sqlite3` unavailable), 0 failures.
- `gem build sentry-good_job.gemspec` and `Gem::Package#verify`: ok for 7.0.2.
- Cold `require "sentry-good_job"` under bundler: wall 0.298 s, RSS after 52,527,104 bytes, RSS delta 28,508,160 bytes. Single-machine observation, not a release budget.

## Next

- Commit the worktree, then run `make release` for tag, RubyGems, and GitHub release.
- Follow up on unwired tags helper issue when convenient.

## Source

- Prior review: `docs/reviews/20261028_engineering-audit-release-preparation.md`
- Changelog draft: `docs/changelogs/20261030113102_release-confirmation-and-changelog-gate.md`
- Deferred issue: `docs/issues/20261030113102_unwired-enhance-sentry-tags.md`
