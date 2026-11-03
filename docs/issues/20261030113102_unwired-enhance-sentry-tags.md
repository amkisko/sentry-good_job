Live finding from the 2026-10-30 engineering audit. Closed in 7.0.3.

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Confirmed sentry-rails `SentryReporter` exposes `sentry_context` and `record_producer_span`, not a tags enhancement hook.
- Delete `ActiveJobExtensions.enhance_sentry_tags` and its unit examples.
- Keep `ContextHelpers.add_tags` as a documented manual helper for host apps.

## Effects

- Production setup patches only `SentryReporter.sentry_context`.
- Tags helper no longer implies automatic tag shipping from setup.
- README states the manual-helper contract.

## Next

None for this issue.

## Source

- lib/sentry/good_job/active_job_extensions.rb
- lib/sentry/good_job/context_helpers.rb
- docs/reviews/20261103171803_engineering-prose-release-audit.md
- docs/reviews/20261030113102_engineering-audit-release-preparation.md
