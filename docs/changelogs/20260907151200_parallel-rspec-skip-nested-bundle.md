## Participants

- amkisko

## Decisions

- Spawn parallel RSpec workers as rspec, not bundle exec rspec, when the parent is already bundle exec polyrun.

## Effects

- Makefile test, usr/bin/release.rb coverage run, and spec/README.md use -- rspec after parallel-rspec flags.
- This is a local runner workaround for Ruby 4.0 nested bundle exec. CHANGELOG.md has no Unreleased bullet because the published gem contract did not change.

## Next

- Continue make release through gem build when ready.
