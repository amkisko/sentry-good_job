Engineering note for the 7.0.2 release tooling changes.

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Treat end-of-input at the release confirmation prompt as rejection.
- Accept empty Enter or case-insensitive `y` as confirmation; reject every other answer.
- Abort release when `CHANGELOG.md` lacks a version heading that matches `lib/sentry/good_job/version.rb`.
- Require a clean git status including untracked files before `gem push`.
- Push `HEAD` and the version tag together; create the GitHub release after the tag exists.

## Effects

- `usr/lib/release_version_check.rb` owns confirmation and changelog heading checks.
- `usr/bin/release.rb` calls those checks before build and after tests.
- Specs cover confirmation EOF, accepted answers, and changelog heading acceptance and rejection.

## Next

- Commit the worktree, then run `make release` to publish 7.0.2.

## Source

- `usr/bin/release.rb`
- `usr/lib/release_version_check.rb`
- `spec/release_version_check_spec.rb`
- `docs/reviews/20261030113102_engineering-audit-release-preparation.md`
