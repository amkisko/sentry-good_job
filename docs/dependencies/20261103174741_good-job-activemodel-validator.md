# good_job Configuration::Validator needs ActiveModel

## Dependency

- name: good_job
- version constraint: gemspec `>= 3.0, < 5.0`; lock / appraisal `4.24.1`
- lockfile: `Gemfile.lock`, `gemfiles/rails8.gemfile.lock`, `gemfiles/ruby34.gemfile.lock`

## Symptom

Requiring `good_job` after only `active_job` raises:

`NameError: uninitialized constant GoodJob::Configuration::Validator::ActiveModel`

at `lib/good_job/configuration/validator.rb` (`include ActiveModel::Model`).

## Evidence

- Reproduced under Ruby 4.0.7 with good_job 4.24.1 in this gem's unit suite (`spec/spec_helper.rb` previously did `require "active_job"` then `require "good_job"`).
- good_job 4.19.2 did not hit this path in the same helper.
- Rails apps load ActiveModel via the railtie; bare ActiveJob + good_job does not.

## Suggested fix

- Workaround in this repo: `require "active_model"` before `require "good_job"` in `spec/spec_helper.rb`.
- Upstream: require `active_model` inside `configuration/validator.rb` (or from `configuration.rb`) so the file is self-contained.

## Next

- Keep the local require until upstream loads ActiveModel itself.
- Optional: open or track an upstream good_job issue.

## Source

- https://github.com/bensheldon/good_job
- `lib/good_job/configuration/validator.rb` in good_job 4.24.1
- Downstream: `spec/spec_helper.rb` in this repository
