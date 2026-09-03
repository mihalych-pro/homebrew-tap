# typed: false
# frozen_string_literal: true

# Annotates `brew livecheck --json` with a status word.
#
#   brew livecheck --tap=<tap> --json | brew ruby scripts/report-versions.rb
#
# `brew livecheck` prints "current ==> latest" and colours the latter green
# when it considers the package outdated, but never spells that out — and the
# two versions can read as different while comparing equal (`2.01.3` is the
# same version as `2.1.3` to Homebrew), which makes a plain line ambiguous.
# The `outdated` flag in the JSON is the authority, so it is used here.

require "json"

module VersionReport
  extend Utils::Output::Mixin

  module_function

  def line(entry)
    name = entry["formula"] || entry["cask"]
    version = entry["version"] || {}

    if entry["status"]
      reason = Array(entry["messages"]).join("; ").presence || entry["status"]
      "#{name}: skipped - #{reason}"
    elsif version["outdated"]
      # Tty.green collapses to nothing when stdout is not a terminal.
      "#{name}: #{version["current"]} ==> #{Tty.green}#{version["latest"]} (outdated)#{Tty.reset}"
    else
      "#{name}: #{version["current"]} (up to date)"
    end
  end

  # livecheck tags each entry with either a "formula" or a "cask" key, which is
  # also what tells the two apart in its output -- nothing else does.
  SECTIONS = [["formula", "Formulae"], ["cask", "Casks"]].freeze

  def main
    input = $stdin.read
    odie "no input; pipe `brew livecheck --json` into this script" if input.blank?

    entries = JSON.parse(input)
    SECTIONS.each do |key, title|
      group = entries.select { |entry| entry.key?(key) }
      next if group.empty?

      ohai title
      group.sort_by { |entry| entry[key] }.each { |entry| puts line(entry) }
    end
  rescue JSON::ParserError => e
    odie "could not parse brew livecheck output: #{e.message}"
  end
end

VersionReport.main
