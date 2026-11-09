#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

# A skip item is a version string or { "solargraph" => version, "rails" => [...] }
#
# @param item [String, Hash{String => String, Array<String>}]
# @return [String]
def skip_version(item)
  item.is_a?(Hash) ? item["solargraph"].to_s : item.to_s
end

USAGE = <<~TXT
  Usage:
    ruby script/copy_definitions.rb FROM_VERSION TO_VERSION [--dry-run]

  Example:
    ruby script/copy_definitions.rb 0.57.0 0.58.0
TXT

from_version = ARGV.shift
to_version   = ARGV.shift
dry_run      = ARGV.delete("--dry-run")

if from_version.nil? || to_version.nil? || !ARGV.empty?
  warn USAGE
  exit 1
end

patterns = [
  "spec/definitions/*.yml",
  "spec/definitions/core/*.yml"
]

files = patterns.flat_map { |p| Dir.glob(p) }.uniq.sort
if files.empty?
  warn "No files matched: #{patterns.join(', ')}"
  exit 1
end

total_files_changed = 0
total_entries_changed = 0

files.each do |path|
  data = YAML.load_file(path)

  unless data.is_a?(Hash)
    warn "Skipping #{path}: expected top-level mapping (Hash), got #{data.class}"
    next
  end

  file_entries_changed = 0

  # @param entry [Hash]
  data.each_value do |entry|
    next unless entry.is_a?(Hash)

    # @type [Array<String, Hash{String => String, Array<String>}>]
    skip = entry["skip"]
    next unless skip.is_a?(Array)

    from = skip.find { |item| skip_version(item) == from_version }
    next if from.nil?
    next if skip.any? { |item| skip_version(item) == to_version }

    # Rails-scoped skips exist only for Solargraph releases below 0.60
    legacy = /\A\d+(\.\d+)+\z/.match?(to_version.to_s) && Gem::Version.new(to_version.to_s) < Gem::Version.new("0.60")
    skip.append(from.is_a?(Hash) && legacy ? from.merge("solargraph" => to_version) : to_version)
    skip.sort_by! { |item| [skip_version(item), item.is_a?(Hash) ? 1 : 0] }

    file_entries_changed += 1
  end

  next if file_entries_changed.zero?

  total_files_changed += 1
  total_entries_changed += file_entries_changed

  if dry_run
    puts "[DRY RUN] Would update #{path} (#{file_entries_changed} entr#{file_entries_changed == 1 ? 'y' : 'ies'})"
  else
    File.write(path, YAML.dump(data))
    puts "Updated #{path} (#{file_entries_changed} entr#{file_entries_changed == 1 ? 'y' : 'ies'})"
  end
end

if dry_run
  puts "[DRY RUN] Done. Files to change: #{total_files_changed}, entries to change: #{total_entries_changed}"
else
  puts "Done. Files changed: #{total_files_changed}, entries changed: #{total_entries_changed}"
end
