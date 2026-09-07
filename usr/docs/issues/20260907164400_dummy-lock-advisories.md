Recorded 2026-09-07. After 7.0.0 shipped, CI bundler-audit still failed on the dummy and rails8 appraisal locks. Gemfile.lock was on Rails 8.0.3, rack 3.2.3, crass 1.0.6, erb 5.1.1, and loofah 2.24.1.

## Participants

- amkisko

## Decisions

- Relock the dummy graph to railties >= 8.0.4.1 and rack >= 3.2.6, plus crass, erb, and loofah floors that bundler-audit also matched.
- Keep the rails8 appraisal on the 8.0 line with gem "rails", "~> 8.0.4", ">= 8.0.4.1". Root lock may resolve to 8.1 because the Gemfile does not pin ~> 8.0.
- Conservative bundle lock --update=railties left actionpack at 8.0.3. Unlock the Rails family together, or the floor cannot take effect.
- After the named pins moved, rails8 still matched concurrent-ruby, nokogiri, rack-session, and rails-html-sanitizer. Floor those in the rails8 appraisal so that lockfile can pass the same job.

## Effects

- Gemfile.lock pins railties 8.1.3.1, rack 3.2.7, crass 1.0.7, erb 6.0.7, loofah 2.25.2. json stays 2.21.2.
- gemfiles/rails8.gemfile.lock pins rails 8.0.5.1 with the same rack, crass, erb, and loofah floors, plus concurrent-ruby 1.3.8, nokogiri 1.19.4, rack-session 2.1.2, and rails-html-sanitizer 1.7.1.
- gemfiles/ruby34.gemfile.lock already met the Rails and loofah floors; rack moved 3.2.6 to 3.2.7 and erb 6.0.6 to 6.0.7.
- CHANGELOG.md was not given an Unreleased bullet. This is a lockfile and development-graph refresh.

## Next

- Appraisal lockfiles stay outside Dependabot directory /. Keep CI bundler-audit as the gate.
- Do not treat .trunk linter fixture Gemfile.lock files as product locks.

## Source

- usr/docs/changelogs/20260907164400_dummy-lock-advisory-relock.md
- usr/docs/dependencies/20260907164400_test-graph-advisory-relock.md
