Live finding from the 2026-10-30 engineering audit. Does not block 7.0.2.

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Leave `ActiveJobExtensions.enhance_sentry_tags` public and tested, but do not invent a sentry-rails tags hook in this release.
- Keep `ContextHelpers.add_tags` as the single implementation; `enhance_sentry_tags` delegates to it.

## Effects

- Production setup patches only `SentryReporter.sentry_context`. Tags helpers have unit coverage and no call site on the setup path.
- Context duplication between `ContextHelpers` and `ActiveJobExtensions` is removed by delegation.

## Next

- Confirm whether sentry-rails exposes a tags enhancement point worth wiring.
- If no hook exists and no caller needs the method, delete `enhance_sentry_tags` and its specs in a later patch, or document it as a manual helper next to `ContextHelpers.add_tags`.

## Source

- `lib/sentry/good_job/active_job_extensions.rb`
- `lib/sentry/good_job/context_helpers.rb`
- `spec/sentry/good_job/active_job_extensions_spec.rb`
- `docs/reviews/20261030113102_engineering-audit-release-preparation.md`
