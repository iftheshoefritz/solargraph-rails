require 'spec_helper'

RSpec.describe Solargraph::Rails::RailsApi do
  let(:scoped_path) { 'ActionController::HttpAuthentication::Token::ControllerMethods#authenticate_with_http_token' }
  let(:gem_rbs) { true }
  let(:rails_api) { described_class.new }

  before { allow(rails_api).to receive(:gem_rbs_supported?).and_return(gem_rbs) }

  # @param version [String, nil]
  def with_actionpack(version)
    specs = Gem.loaded_specs.except('actionpack')
    specs['actionpack'] = Gem::Specification.new('actionpack', version) if version
    allow(Gem).to receive(:loaded_specs).and_return(specs)
  end

  # @return [Array<String>]
  def global_paths
    rails_api.global(nil).map(&:path)
  end

  it 'loads annotations scoped to actionpack before 7.2 for actionpack 7.1' do
    with_actionpack('7.1.5')

    expect(global_paths).to include(scoped_path)
  end

  it 'skips annotations scoped to actionpack before 7.2 for actionpack 7.2' do
    with_actionpack('7.2.0')

    expect(global_paths).not_to include(scoped_path)
  end

  it 'skips version-scoped annotations when actionpack is not loaded' do
    with_actionpack(nil)

    expect(global_paths).not_to include(scoped_path)
  end

  context 'when Solargraph cannot read gem RBS' do
    let(:gem_rbs) { false }

    it 'loads version-scoped annotations for actionpack 7.2' do
      with_actionpack('7.2.0')

      expect(global_paths).to include(scoped_path)
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

  it 'loads unscoped annotations whatever the actionpack version' do
    with_actionpack('7.2.0')

    expect(global_paths).to include('ActionController::Metal#params')
  end
end
