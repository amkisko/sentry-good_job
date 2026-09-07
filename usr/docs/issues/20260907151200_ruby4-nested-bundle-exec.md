## Participants

- amkisko

## Decisions

- Keep workers on rspec after parallel-rspec flags. Do not nest bundle exec under bundle exec polyrun on Ruby 4.0 and Bundler 2.5.9.
- Do not bump Bundler or polyrun only to hide the nested binstub. Record the defect and apply the smallest command change.

## Effects

- make release polyrun shards printed passing examples then exited 1 on every worker. LoadError came from RubyGems bin/bundle, not from an RSpec failure.
- Makefile, usr/bin/release.rb, and spec/README.md now pass -- rspec so children inherit the parent Bundler environment.

## Next

- Continue make release through gem build. Do not gem push or tag until asked.

Observed: POLYRUN_COVERAGE=1 bundle exec polyrun parallel-rspec --workers 5 --merge-failures -- rspec finished 5 workers exit 0 on Ruby 4.0.0.
