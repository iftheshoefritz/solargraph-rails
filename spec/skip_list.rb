# frozen_string_literal: true

require 'yaml'

# Reads and edits the `skip` value of a spec/definitions entry. It is
# `true`, `false`, a Solargraph version, or a list whose items are either
# a Solargraph version (skipped on every Rails version) or a hash scoping
# one Solargraph version to some Rails versions:
#
#   skip:
#   - 0.48.0
#   - solargraph: 0.57.0
#     rails: ['7.0', '7.1']
module SkipList
  WILDCARD = 'branch-castwide-master'
  WORKFLOW = File.expand_path('../.github/workflows/test.yml', __dir__)

  module_function

  # @param skip [Boolean, String, Array<String, Hash>, nil]
  # @param solargraph_version [String]
  # @param rails_version [String] major.minor
  # @return [Boolean]
  def applies?(skip, solargraph_version, rails_version)
    return true if skip == true
    return false unless skip

    items(skip).any? do |item|
      version_matches?(version_of(item), solargraph_version) &&
        (item.is_a?(String) || rails_of(item).include?(rails_version))
    end
  end

  # Records a failure on this Solargraph and Rails version: extends the
  # version's Rails-scoped item if there is one, else skips the version on
  # every Rails version.
  #
  # @param data [Hash] a definitions entry
  # @param solargraph_version [String]
  # @param rails_version [String]
  # @param matrix_rails [Array<String>] Rails versions CI runs with this Solargraph version
  # @return [void]
  def add(data, solargraph_version, rails_version, matrix_rails)
    list = items(data['skip'])
    scoped = list.find { |item| item.is_a?(Hash) && version_of(item) == solargraph_version }
    if scoped
      rails = (rails_of(scoped) | [rails_version]).sort
      list.delete(scoped)
      list << ((matrix_rails - rails).empty? ? solargraph_version : scoped.merge('rails' => rails))
    else
      list << solargraph_version
    end
    data['skip'] = sorted(list)
  end

  # Records a pass on this Solargraph and Rails version: a version skipped
  # on every Rails version stays skipped on the other matrix Rails versions,
  # since one Rails version passing says nothing about the others.
  #
  # @param data [Hash] a definitions entry
  # @param solargraph_version [String]
  # @param rails_version [String]
  # @param matrix_rails [Array<String>]
  # @return [void]
  def remove(data, solargraph_version, rails_version, matrix_rails)
    unless data['skip'].is_a?(Array) || data['skip'].is_a?(String)
      data['skip'] = false
      return
    end

    list = items(data['skip']).flat_map do |item|
      next [item] unless version_of(item) == solargraph_version

      rails = (item.is_a?(String) ? matrix_rails : rails_of(item)) - [rails_version]
      rails.empty? ? [] : [{ 'solargraph' => solargraph_version, 'rails' => rails }]
    end
    data['skip'] = list.empty? ? false : sorted(list)
  end

  # Rails versions (major.minor) that .github/workflows/test.yml runs with
  # a Solargraph version, after its `exclude` entries.
  #
  # @param solargraph_version [String]
  # @return [Array<String>]
  def matrix_rails_versions(solargraph_version)
    matrix = YAML.load_file(WORKFLOW).dig('jobs', 'rspec', 'strategy', 'matrix')
    excludes = (matrix['exclude'] || []).select { |ex| ex['solargraph-version'] == solargraph_version }
    excluded = excludes.map { |ex| ex['versions'] }
    versions = matrix['versions'].reject { |v| excluded.include?(v) }
    versions.map { |v| "#{v['rails-major']}.#{v['rails-minor']}" }.uniq
  end

  # @param list [Array<String, Hash>]
  # @return [Array<String, Hash>]
  def sorted(list)
    list.uniq.sort_by { |item| [version_of(item), item.is_a?(String) ? [] : rails_of(item)] }
  end

  # @param skip [Boolean, String, Array<String, Hash>, nil]
  # @return [Array<String, Hash>]
  def items(skip)
    case skip
    when Array then skip.dup
    when String then [skip]
    else []
    end
  end

  # @param item [String, Hash]
  # @return [String]
  def version_of(item)
    item.is_a?(Hash) ? item['solargraph'].to_s : item.to_s
  end

  # @param item [Hash]
  # @return [Array<String>]
  def rails_of(item)
    Array(item['rails']).map(&:to_s)
  end

  # @param skipped [String]
  # @param solargraph_version [String]
  # @return [Boolean]
  def version_matches?(skipped, solargraph_version)
    skipped == solargraph_version ||
      (skipped == WILDCARD && solargraph_version.start_with?('branch-'))
  end
end
