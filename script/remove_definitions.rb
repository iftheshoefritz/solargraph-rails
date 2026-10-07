#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

USAGE = <<~TXT
  Usage:
    ruby script/remove_definitions.rb VERSION [--dry-run]

  Example:
    ruby script/remove_definitions.rb 0.58.1
TXT

version = ARGV.shift
dry_run = ARGV.delete("--dry-run")

if version.nil? || !ARGV.empty?
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

    # @type [Array<String>]
    skip = entry["skip"]
    next unless skip.is_a?(Array)
    next unless skip.delete(version)

    # Same shape spec/definitions.rb#remove_skip leaves behind
    entry["skip"] = false if skip.empty?

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
