Recorded 2026-09-07. sentry-good_job 7.0.0 requires sentry-ruby 7 and skips a nested enqueue span when sentry-rails already records it.

## Participants

- amkisko

## Decisions

- Bump this gem to 7.0.0. gemspec sentry-ruby >= 7.0, < 8.0. Last 6-only line remains 6.2.1.
- At enqueue time, skip this gem's queue.publish span when Sentry::Rails::ActiveJobExtensions::SentryReporter.respond_to?(:record_producer_span). Keep context enhance and latency fallback for unit tests without sentry-rails.
- Pin appraisals to sentry-ruby ~> 7.0.0. rails8 also pins sentry-rails ~> 7.0.0.
- Document job arguments as config.data_collection.queues.

## Effects

- VERSION is 7.0.0.
- README Compatibility is Ruby 3.4+, Good Job 3.x and 4.x, Sentry Ruby SDK 7.x.
- CHANGELOG.md 7.0.0 dated 2026-09-07. RubyGems still lists 6.2.1 as latest.

## Next

- Push main and wait for CI.
- After CI green, run make release to publish 7.0.0.
