Recorded 2026-09-07. Library gem. Scheduled CI bundler-audit failed on json CVE-2026-71847 and, where present, sqlite3 GHSA-mwm8-39rw-8826.

## Participants

- amkisko

## Decisions

- Bump json to 2.21.2 in Gemfile.lock and appraisal lockfiles. Keep json on 2.x because rubocop declares json ~> 2.3.
- Bump sqlite3 to 2.9.6 in the test graph where the pin was still affected. Raise the development gemspec floor to >= 2.9.6 when this gemspec declared sqlite3.
- Treat CVE-2026-71847 as not_affected for this gem execute path. The advisory names JSON::ResumableParser#partial_value.
- Treat GHSA-mwm8-39rw-8826 as not_affected for the published gem runtime when sqlite3 is development-only. Still bump the test graph so bundler-audit can pass.
- Leave Dependabot bundler at directory /. Appraisal *.gemfile names are not a working Dependabot directory.

## Effects

- Root and appraisal lockfiles pin json 2.21.2. sqlite3 pins 2.9.6 where that gem was in the graph.
- Dependency records live under usr/docs/dependencies.

## Next

- Appraisal lockfiles stay outside Dependabot directory /. Keep CI bundler-audit as the gate unless a later pass finds a supported Dependabot layout for those files.

## Source

- usr/docs/changelogs/20260907141000_advisory-lockfile-refresh.md
- usr/docs/dependencies/20260907141000_json-cve-2026-71847.md
- https://github.com/ruby/json/security/advisories/GHSA-9hj4-r449-hfvc
- https://github.com/sparklemotion/sqlite3-ruby/security/advisories/GHSA-mwm8-39rw-8826
