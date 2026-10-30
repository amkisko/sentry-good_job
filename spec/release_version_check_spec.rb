# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require_relative "../usr/lib/release_version_check"

RSpec.describe ReleaseVersionCheck do
  describe ".confirmation_accepted?" do
    it "accepts an explicit yes or an interactive default" do
      expect(described_class.confirmation_accepted?("y\n")).to be(true)
      expect(described_class.confirmation_accepted?("Y\n")).to be(true)
      expect(described_class.confirmation_accepted?("\n")).to be(true)
    end

    it "rejects EOF and other answers" do
      expect(described_class.confirmation_accepted?(nil)).to be(false)
      expect(described_class.confirmation_accepted?("n\n")).to be(false)
    end
  end

  describe ".changelog_includes_version?" do
    def write_changelog(body)
      path = File.join(Dir.mktmpdir, "CHANGELOG.md")
      File.write(path, body)
      path
    end

    it "accepts plain and Keep a Changelog version headings" do
      path = write_changelog(<<~MD)
        # Changelog

        ## 7.0.2 (2026-10-30)
        ## [7.0.1] - 2026-09-09
      MD

      expect(described_class.changelog_includes_version?("7.0.2", path: path)).to be(true)
      expect(described_class.changelog_includes_version?("7.0.1", path: path)).to be(true)
    end

    it "rejects missing versions and Unreleased headings" do
      path = write_changelog(<<~MD)
        # Changelog

        ## Unreleased
        ## 7.0.2 (Unreleased)
        ## 7.0.1 (2026-09-09)
      MD

      expect(described_class.changelog_includes_version?("7.0.2", path: path)).to be(false)
      expect(described_class.changelog_includes_version?("9.9.9", path: path)).to be(false)
      expect(described_class.changelog_includes_version?("7.0.1", path: path)).to be(true)
    end
  end

  describe ".require_changelog_version!" do
    it "aborts when the changelog file is missing" do
      expect {
        described_class.require_changelog_version!(version: "7.0.2", path: "tmp/missing-changelog.md")
      }.to raise_error(SystemExit)
    end

    it "aborts when the version heading is absent" do
      path = File.join(Dir.mktmpdir, "CHANGELOG.md")
      File.write(path, "# Changelog\n\n## 1.0.0\n")

      expect {
        described_class.require_changelog_version!(version: "7.0.2", path: path)
      }.to raise_error(SystemExit)
    end

    it "returns when the version heading is present" do
      path = File.join(Dir.mktmpdir, "CHANGELOG.md")
      File.write(path, "# Changelog\n\n## 7.0.2 (2026-10-30)\n")

      expect {
        described_class.require_changelog_version!(version: "7.0.2", path: path)
      }.not_to raise_error
    end
  end
end
