## Participants

- amkisko

## Decisions

- Relock the dummy and appraisal test graphs so bundler-audit no longer matches Rails 8.0.3, rack 3.2.3, crass 1.0.6, erb 5.1.1, or loofah 2.24.1.
- Put the floors in Gemfile and the rails8 appraisal. Leave the published gemspec free of those packages.
- Skip a CHANGELOG.md Unreleased bullet. This is not a public gem contract change.

## Effects

- Dummy lock now resolves railties 8.1.3.1 and rack 3.2.7. rails8 appraisal stays on rails 8.0.5.1.
- bundle-audit check --no-update reported no vulnerabilities on Gemfile.lock, gemfiles/rails8.gemfile.lock, and gemfiles/ruby34.gemfile.lock after the relock.

## Source

- usr/docs/issues/20260907164400_dummy-lock-advisories.md
- usr/docs/dependencies/20260907164400_test-graph-advisory-relock.md
