require 'spec_helper'

RSpec.describe Solargraph::Rails::RailsApi do
  let(:scoped_paths) do
    [
      'ActionController::HttpAuthentication::Token::ControllerMethods#authenticate_with_http_token',
      'ActiveRecord::Base.create!',
      'ActiveRecord::Persistence::ClassMethods#create'
    ]
  end
  let(:gem_rbs) { true }
  let(:rails_api) { described_class.new }

  before { allow(rails_api).to receive(:gem_rbs_supported?).and_return(gem_rbs) }

  # @param version [String, nil]
  def with_rails(version)
    specs = Gem.loaded_specs.except('railties')
    specs['railties'] = Gem::Specification.new('railties', version) if version
    allow(Gem).to receive(:loaded_specs).and_return(specs)
  end

  # @return [Array<String>]
  def global_paths
    rails_api.global(nil).map(&:path)
  end

  it 'loads annotations scoped to Rails before 7.2 for Rails 7.1' do
    with_rails('7.1.5')

    expect(global_paths).to include(*scoped_paths)
  end

  it 'skips annotations scoped to Rails before 7.2 for Rails 7.2' do
    with_rails('7.2.0')

    expect(global_paths).not_to include(*scoped_paths)
  end

  it 'skips Rails-version-scoped annotations when Rails is not loaded' do
    with_rails(nil)

    expect(global_paths).not_to include(*scoped_paths)
  end

  context 'when Solargraph cannot read gem RBS' do
    let(:gem_rbs) { false }

    it 'loads version-scoped annotations for Rails 7.2' do
      with_rails('7.2.0')

      expect(global_paths).to include(*scoped_paths)
    end
  end

  it 'loads annotations scoped to Solargraph before 0.60 on Solargraph 0.59' do
    stub_const('Solargraph::VERSION', '0.59.2')

    expect(global_paths).to include('Module#presence')
  end

  it 'skips annotations scoped to Solargraph before 0.60 from Solargraph 0.60.0 on' do
    stub_const('Solargraph::VERSION', '0.60.0.dev-castwide-master')

    expect(global_paths).not_to include('Module#presence')
  end

  it 'reads gem RBS from Solargraph 0.53.0 on' do
    stub_const('Solargraph::VERSION', '0.53.0.dev-castwide-master')

    expect(described_class.new.send(:gem_rbs_supported?)).to be(true)
  end

  it 'reads no gem RBS before Solargraph 0.53.0' do
    stub_const('Solargraph::VERSION', '0.52.0')

    expect(described_class.new.send(:gem_rbs_supported?)).to be(false)
  end

  it 'loads unscoped annotations whatever the Rails version' do
    with_rails('7.2.0')

    expect(global_paths).to include('ActionController::Metal#params')
  end
end
