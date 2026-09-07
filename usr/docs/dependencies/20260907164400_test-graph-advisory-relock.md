## Dependency

- railties / rails (was 8.0.3 in Gemfile.lock; rails8 appraisal was 8.0.4)
- rack (was 3.2.3 in Gemfile.lock; rails8 appraisal was 3.2.4)
- crass (was 1.0.6)
- erb (was 5.1.1 in Gemfile.lock)
- loofah (was 2.24.1 in Gemfile.lock; rails8 appraisal was 2.25.0)
- Constraint in this repo: none in the gemspec. Floors live in Gemfile and the rails8 appraisal only.
- Lockfiles: Gemfile.lock, gemfiles/rails8.gemfile.lock, gemfiles/ruby34.gemfile.lock

## Symptom

bundler-audit failed CI after 7.0.0 on the dummy lock and the rails8 appraisal lock. Matches included Rails 8.0.3, rack 3.2.3, crass 1.0.6, erb below 6.0.4, and loofah below 2.25.2.

## Evidence

- Rails 8.0.4.1 and 8.1.2.1 are the documented security floors on those lines. Latest matching 8.0.x in this pass is 8.0.5.1.
- rack affected >= 3.2, < 3.2.6 (GHSA-rx22-g9mx-qrhv / CVE-2026-26962). Patched >= 3.2.6. This pass pins 3.2.7.
- crass nested CSS stack exhaustion: GHSA-6jxj-px6v-747w. Patched >= 1.0.7.
- erb @_init Marshal gadget: CVE-2026-41316 / GHSA-q339-8rmv-2mhv. Patched >= 6.0.4. This pass pins 6.0.7.
- loofah GHSA-9wjq-cp2p-hrgf (CVE-2026-73490) and GHSA-8whx-365g-h9vv (CVE-2026-73491). Patched >= 2.25.2.
- After those pins moved, rails8 still matched concurrent-ruby < 1.3.7, nokogiri 1.18.10, rack-session 2.1.1, and rails-html-sanitizer 1.6.2. Those were relocked in the same appraisal graph.

## Suggested fix

Add test-graph floors and relock. Do not add these packages to the published gemspec. Keep rails8 on ~> 8.0.4 so that cell does not jump to 8.1.

## Trigger

- bundler-audit scanner match on the post-7.0.0 dummy and rails8 locks.

## Assessment target

- CI and test graphs: Gemfile.lock and appraisal locks.
- Published gem runtime: these packages are not gemspec dependencies.

## Advisory

- Rails 8.0.3 and 8.0.4 below 8.0.4.1 (security releases 8.0.4.1 and 8.1.2.1)
- rack GHSA-rx22-g9mx-qrhv / CVE-2026-26962
- crass GHSA-6jxj-px6v-747w
- erb CVE-2026-41316 / GHSA-q339-8rmv-2mhv
- loofah GHSA-9wjq-cp2p-hrgf / CVE-2026-73490, GHSA-8whx-365g-h9vv / CVE-2026-73491

## Status

- CI and test graphs: fixed after the lockfiles named above pin patched versions and bundler-audit reports no vulnerabilities on those three files.
- Published gem execute path: not_affected. The gemspec does not depend on rails, rack, crass, erb, or loofah.

## Applicability

- Vulnerable component present in the pre-fix dummy and rails8 locks.
- Exploit conditions are in the host Rails stack, not in sentry-good_job code.

## Priority

- CI graph: high because bundler-audit fails the security job on version match.
- Published gem execute path: low. Component not present in the published gemspec.

## Disposition

- Upgrade the test graph. bundle lock with the Rails family unlocked so railties can leave 8.0.3. Confirm json stays 2.21.2 and rails8 stays on 8.0.x.

## Next

- Keep the published gemspec free of these floors unless a later feature depends on them at runtime.

## Source

- usr/docs/issues/20260907164400_dummy-lock-advisories.md
- https://github.com/rails/rails/releases
- https://github.com/rack/rack/security/advisories
- https://github.com/rgrove/crass/security/advisories/GHSA-6jxj-px6v-747w
- https://github.com/ruby/erb/security/advisories/GHSA-q339-8rmv-2mhv
- https://github.com/flavorjones/loofah/security/advisories
