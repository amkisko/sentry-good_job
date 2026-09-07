## Dependency

- bundler 2.5.9 (Ruby 4.0 default gem; Gemfile.lock BUNDLED WITH 2.5.9)
- rubygems shipped with Ruby 4.0.0 (Gem.activate_and_load_bin_path)
- polyrun 2.2.1 (direct development dependency, >= 2.2.0). parallel-rspec defaults to bundle exec rspec after --.

## Symptom

make release runs POLYRUN_COVERAGE=1 bundle exec polyrun parallel-rspec. Examples pass. All five worker processes then exit 1. Kernel#load cannot find gems/bundler-2.5.9/lib/gems/bundler-2.5.9/exe/bundle. Stack is Gem.activate_and_load_bin_path from RubyGems bin/bundle. Workers also print already initialized constant Gem::Platform warnings at start.

## Evidence

- polyrun parallel-rspec with no command after -- spawns bundle exec rspec. The parent is already bundle exec polyrun. Child env keeps BUNDLE_BIN_PATH.
- RubyGems 4.0 activate_and_load_bin_path loads BUNDLE_BIN_PATH when bundler <= 2.5.22, then still loads spec.bin_file. The computed bin path doubles gems/bundler-2.5.9 under lib.
- Repro: POLYRUN_COVERAGE=1 bundle exec polyrun parallel-rspec --workers 5 --merge-failures. Same LoadError on every shard. bundle exec rspec of one spec file without a nested bundle exits 0.
- CI quality and test jobs use Ruby 3.4, so they may not hit this path.

## Suggested fix

In this repo, pass -- rspec after parallel-rspec flags so workers inherit the parent Bundler env and do not start bin/bundle again. Upstream: polyrun should default to rspec when already inside bundle exec, or Bundler.with_original_env before nested bundle. Bundler newer than 2.5.22 skips the BUNDLE_BIN_PATH load workaround.

## Next

- Keep Makefile and usr/bin/release.rb on -- rspec until polyrun or Bundler ships a nested-exec fix on Ruby 4.0.
- Report the doubled exe path to polyrun and/or RubyGems if a later local run still needs nested bundle exec.

## Trigger

- make release polyrun shards on Ruby 4.0.0 with Bundler 2.5.9, 2026-09-07.

## Assessment target

- Local release and make test on Ruby 4.0.
- CI currently pins Ruby 3.4.

## Status

- Worked around in this repo by spawning rspec without a nested bundle exec.
