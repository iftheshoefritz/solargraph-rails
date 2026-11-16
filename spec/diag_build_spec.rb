require 'spec_helper'
require 'json'

# Temporary diagnostic: dumps the Solargraph pins behind ActiveRecord::Base.build
RSpec.describe 'diag build' do
  it 'dumps ActiveRecord::Base.build pins' do
    cells = %w[0.62.1 branch-castwide-master]
    skip 'diagnostic cell only' unless ENV['MATRIX_RAILS_VERSION'] == '8.0' && cells.include?(ENV['MATRIX_SOLARGRAPH_VERSION'])

    extend TypeMembers
    map = rails_workspace
    pins = map.get_methods('ActiveRecord::Base', scope: :class, visibility: %i[public protected private]).select { |p| p.name == 'build' }
    relevant = pins.select { |p| p.path == pins.first.path }
    meh = %w[BasicObject Object undefined]
    good, mehs = relevant.partition { |p| meh.none? { |m| member_tags(p.typify(map)).include?(m) } }
    pick = (good.sort_by { |p| member_tags(p.typify(map)).sort } + mehs.sort_by { |p| member_tags(p.typify(map)).sort }).first
    lock = File.read("spec/rails8/rbs_collection.lock.yaml") rescue ''
    path_pins = map.get_path_pins('ActiveRecord::Persistence::ClassMethods#build')
    describe_pin = lambda do |p|
      { 'class' => p.class.name, 'path' => p.path,
        'loc' => p.location&.then { |l| "#{l.filename}:#{l.range.start.line}" },
        'source' => (p.respond_to?(:source) ? p.source.to_s : nil),
        'return_type' => p.return_type.to_s, 'typify' => member_tags(p.typify(map)),
        'sigs' => (p.respond_to?(:signatures) ? p.signatures.map { |s| s.return_type.to_s } : nil) }
    end
    out = {
      'sg' => Solargraph::VERSION, 'rbs' => (RBS::VERSION rescue nil),
      'activerecord' => Gem.loaded_specs['activerecord']&.version.to_s,
      'lock_revisions' => lock.scan(/revision: (\h+)/).flatten.uniq,
      'lock_activerecord' => lock[/name: activerecord\n  version: '[^']*'/],
      'annotations' => Solargraph::Rails::RailsApi.instance.send(:annotation_paths).map { |f| f.sub(/.*annotations\//, '') },
      'get_methods' => pins.map { |p| describe_pin.call(p).merge('relevant' => relevant.include?(p)) },
      'path_pins' => path_pins.map { |p| describe_pin.call(p) },
      'picked' => pick && pins.index(pick), 'result' => pick && member_tags(pick.typify(map)).sort.uniq
    }
    puts "DIAG-BUILD #{JSON.generate(out)}"
  end
end
