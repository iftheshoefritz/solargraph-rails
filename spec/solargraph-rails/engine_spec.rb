require 'spec_helper'
require 'tmpdir'

RSpec.describe Solargraph::Rails::Engine do
  # Duck type of Solargraph::Metagem, which older Solargraph lacks
  let(:gem_class) { Struct.new(:full_path, :require_paths) }

  let(:root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(root) }

  # @param path [String]
  # @param content [String]
  # @return [void]
  def write(path, content = "module Foo; end\n")
    file = File.join(root, path)
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, content)
  end

  # @return [Array<String>]
  def directories
    described_class.instance.extra_source_paths(gem_class.new(root, ['lib']))
  end

  context 'with an engine' do
    before do
      write 'lib/engine_gem/engine.rb', "module EngineGem\n  class Engine < ::Rails::Engine\n  end\nend\n"
      write 'app/models/concerns/engine_gem/broadcastable.rb'
      write 'app/javascript/engine_gem/compiled.rb'
      write 'app/assets/engine_gem/asset.rb'
      write 'test/mailers/previews/engine_gem/mailer_preview.rb'
    end

    it 'returns default autoload roots, without assets or javascript' do
      expect(directories).to eq(['app/models', 'app/models/concerns', 'test/mailers/previews'])
    end

    it 'is supplied by the convention' do
      expect(Solargraph::Rails::Convention.new.extra_source_paths(gem_class.new(root, ['lib'])))
        .to eq(directories)
    end

    it 'maps no extra paths when the convention raises' do
      allow(described_class.instance).to receive(:extra_source_paths).and_raise('unreadable gem')

      expect(Solargraph::Rails::Convention.new.extra_source_paths(gem_class.new(root, ['lib']))).to eq([])
    end
  end

  it 'leaves out mailer previews when the engine has none' do
    write 'lib/engine_gem/engine.rb', "class Engine < Rails::Engine; end\n"
    write 'app/jobs/engine_gem/job.rb'

    expect(directories).to eq(['app/jobs'])
  end

  it 'returns nothing for a gem with app/ that is not an engine' do
    write 'lib/app_gem.rb'
    write 'app/models/app_gem/thing.rb'

    expect(directories).to eq([])
  end

  it 'returns nothing for an engine without app/' do
    write 'lib/engine_gem/engine.rb', "class Engine < Rails::Engine; end\n"

    expect(directories).to eq([])
  end
end
