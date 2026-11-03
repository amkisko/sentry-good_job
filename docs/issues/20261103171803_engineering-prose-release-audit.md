# Engineering, prose, and release audit

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Ship 7.0.3 as a patch after re-auditing published 7.0.2.
- Delete unwired `enhance_sentry_tags`; keep `ContextHelpers.add_tags` for manual host use.
- Remove the skippable_job_adapters example; consolidate cron setup specs; assert latency after super.
- Date product changelog 2026-11-03. Leave tag and gem push to make release after commit.

## Effects

Pipeline: GraphQL-style map for this gem is Railtie ingress -> ActiveJob / cron helpers -> Sentry egress. Queue and worker behavior stay in Good Job and sentry-rails. No first-party UI.

Ranked fixes applied:

1. Unwired tags helper removed (high, observed; sentry-rails has no tags hook).
2. Futile skippable_job_adapters example removed (high, observed).
3. Duplicate cron setup examples collapsed (medium, observed).
4. Unreachable `_sentry_set_span_data` `super` branch removed (high, observed; Concern include on ActiveJob::Base).
5. README, CHANGELOG, and ASCII punctuation pass (house prose).

Deferred:

- Mutex around setup class ivars under threaded boot.
- Require an explicit cron for `add_monitoring_to_job` instead of default hourly.

## Next

- Commit the worktree, then run make release for tag, RubyGems, and GitHub release.
- Optional follow-up: mutex on setup flags; require cron in `add_monitoring_to_job`.

## Source

- docs/reviews/20261103171803_engineering-prose-release-audit.md
- CHANGELOG.md section 7.0.3 (2026-11-03)
- docs/issues/20261030113102_unwired-enhance-sentry-tags.md
- docs/reviews/20261030113102_engineering-audit-release-preparation.md
