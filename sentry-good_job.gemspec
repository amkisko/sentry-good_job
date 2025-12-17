# frozen_string_literal: true

require_relative "lib/sentry/good_job/version"

Gem::Specification.new do |spec|
  spec.name = "sentry-good_job"
  spec.version = Sentry::GoodJob::VERSION
  spec.authors = ["Sentry Team", "Andrei Makarov"]
  spec.summary = "GoodJob integration for the Sentry error logger"
  spec.description = "Adds Sentry instrumentation, context helpers, and cron monitoring support to GoodJob-backed ActiveJob workloads."
  spec.email = "contact@kiskolabs.com"
  spec.license = "MIT"

  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 2.4"
  spec.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "lib/**/*",
      "bin/*",
      "CHANGELOG.md",
      "README.md",
      "LICENSE.txt",
      "CODE_OF_CONDUCT.md",
      "CONTRIBUTING.md",
      "GOVERNANCE.md",
      "SECURITY.md",
      "sentry-good_job.gemspec"
    ].select { |path| File.file?(path) }
  end

  github_root_uri = "https://github.com/amkisko/sentry-good_job"
  spec.homepage = github_root_uri

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{github_root_uri}/tree/main",
    "changelog_uri" => "#{github_root_uri}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{github_root_uri}/issues",
    "documentation_uri" => "http://www.rubydoc.info/gems/#{spec.name}/#{spec.version}"
  }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sentry-ruby", "~> 6"
  spec.add_dependency "good_job", "~> 4"
end
