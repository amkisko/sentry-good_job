## Participants

- amkisko

## Decisions

- Relock json to 2.21.2 in Gemfile.lock and appraisal lockfiles that still carried a vulnerable pin.
- Relock sqlite3 to 2.9.6 where the test graph still pinned an affected line, and raise the development gemspec floor to >= 2.9.6 when this gemspec declared sqlite3.
- Keep json on the 2.x line in library and appraisal locks because rubocop declares json ~> 2.3.
- Leave Dependabot bundler at directory /. Appraisal lockfiles stay on the CI security matrix.

## Effects

- CI bundler-audit jobs that failed on CVE-2026-71847 and GHSA-mwm8-39rw-8826 now have patched pins in the lockfiles touched this pass.
- CHANGELOG.md was not given an Unreleased bullet. This is a lockfile and development-graph refresh, not a public gem contract change.

## Source

- usr/docs/issues/20260907141000_engineering-and-dependency-audit.md
- usr/docs/dependencies/20260907141000_json-cve-2026-71847.md

## Context

Root Gemfile.lock and gemfiles/rails8.gemfile.lock were pinned surgically to json 2.21.2 after an unconstrained json lock re-resolved Rails 8.0 to 8.1 against gem "rails", "~> 8.0.0". sqlite3 on rails8 moved 2.8.1 to 2.9.6 with bundle lock --update=sqlite3 --conservative. gemfiles/ruby34.gemfile.lock already carried a prior WIP resolve and was left as-is. Unused Dependabot npm and docker ecosystems were removed.
