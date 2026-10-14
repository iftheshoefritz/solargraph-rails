require 'spec_helper'

RSpec.describe Solargraph::Rails::Convention do
  let(:error) { RuntimeError.new('boom') }

  before do
    allow(error).to receive(:backtrace).and_return(nil)
    allow(Solargraph.logger).to receive(:warn)
  end

  it 'logs a global failure whose error has no backtrace' do
    allow(Solargraph::Rails::RailsApi.instance).to receive(:global).and_raise(error)

    expect(described_class.new.global(nil)).to be(Solargraph::Convention::Base::EMPTY_ENVIRON)
    expect(Solargraph.logger).to have_received(:warn).with("boom\n")
  end

  it 'logs a local feature failure whose error has no backtrace' do
    allow(Solargraph::Rails::Schema.instance).to receive(:process).and_raise(error)
    source = Solargraph::Source.load_string("class Foo; end\n", 'app/models/foo.rb')

    described_class.new.local(Solargraph::SourceMap.map(source))
    expect(Solargraph.logger).to have_received(:warn).with("boom\n").at_least(:once)
  end
end
