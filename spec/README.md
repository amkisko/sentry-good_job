# Testing

## Commands

Full suite (matches CI: parallel unit specs via Polyrun, then serial integration):

```bash
make test
```

Lint:

```bash
make lint
```

Focused runs:

```bash
bundle exec rspec spec/sentry/good_job/configuration_spec.rb
bundle exec rspec spec/integration
```

Parallel unit specs only:

```bash
bundle exec polyrun parallel-rspec --workers 5 --merge-failures
```

See `polyrun.yml` and `config/polyrun_coverage.yml`.

## Layout

- `spec/sentry/` — unit specs for configuration, helpers, and instrumentation
- `spec/integration/` — Rails + GoodJob integration (runs serially after the parallel suite)

## Guidelines

- Test observable Sentry and GoodJob outcomes, not internal dispatch details.
- Mock only external boundaries (Sentry transport, time).
- Add or update specs before bugfixes; run `make test` before a PR.
- Coverage threshold: `config/polyrun_coverage.yml` when `POLYRUN_COVERAGE=1`.
