#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require_relative "../lib/release_version_check"

POLYRUN_WORKERS = 5

FileUtils.mkdir_p("tmp")

def execute_command(command)
  green = "\033[0;32m"
  red = "\033[1;31m"
  nc = "\033[0m"

  puts "#{green}#{command}#{nc}"
  shell_command = command.include?("|") ? "set -o pipefail; #{command}" : command
  unless system("bash", "-c", shell_command)
    puts "#{red}Command failed: #{command}#{nc}"
    exit 1
  end
end

execute_command("bundle install")
execute_command("bundle exec appraisal generate")
execute_command("bundle exec rubocop -a 2>&1 | tee tmp/rubocop.log")

test_command = "POLYRUN_COVERAGE=1 bundle exec polyrun parallel-rspec --workers #{POLYRUN_WORKERS} --merge-failures 2>&1 | tee tmp/polyrun-rspec.log"
execute_command(test_command)
execute_command("bundle exec rspec spec/integration 2>&1 | tee tmp/rspec-integration.log")

puts "Tests passed. Checking git status..."

git_status = `git diff --shortstat 2>/dev/null`.strip
unless git_status.empty?
  puts "\033[1;31mgit working directory not clean, please commit your changes first \033[0m"
  puts "\033[1;33mNote: rubocop -a may have modified files. Review and commit changes before releasing.\033[0m"
  exit 1
end

gem_name = "sentry-good_job"
version_file = "lib/sentry/good_job/version.rb"
version_content = File.read(version_file)
version = version_content.match(/VERSION\s*=\s*"([0-9.]+)"/)[1]
gem_file = "#{gem_name}-#{version}.gem"

ReleaseVersionCheck.warn_if_already_released(version: version, package_name: gem_name, registry: :rubygems)

execute_command("gem build #{gem_name}.gemspec")

puts "Ready to release #{gem_file} #{version}"
print "Continue? [Y/n] "
answer = $stdin.gets.chomp
unless answer == "Y" || answer.empty?
  puts "Exiting"
  exit 1
end

execute_command("gem push #{gem_file}")
execute_command("git tag #{version} && git push --tags")
execute_command("gh release create #{version} --generate-notes")
