# frozen_string_literal: true

RSpec.describe Definitions do
  subject(:definitions) { described_class.new(map, 'Foo', 'foo') }

  let(:map) { instance_double(Solargraph::ApiMap) }
  let(:pin) { instance_double(Solargraph::Pin::Method, name: 'foo', path: 'Foo#foo') }

  def expect_definition(recorded, actual, allow_improvements:)
    allow(YAML).to receive(:load_file).and_return({ '#foo' => { 'types' => recorded } })
    allow(map).to receive(:get_methods).and_return([pin])
    allow(pin).to receive(:typify).with(map).and_return(Solargraph::ComplexType.parse(actual))
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ALLOW_IMPROVEMENTS').and_return(allow_improvements.to_s)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('CI', nil).and_return(nil)
    expect { definitions.assert_matches_definitions }
  end

  it 'accepts a type for a method recorded as undefined when allowing improvements' do
    expect_definition(['undefined'], 'Hash', allow_improvements: true)
      .to output(/Foo#foo is now typed as \["Hash"\]/).to_stdout
  end

  it 'rejects a type for a method recorded as undefined otherwise' do
    expect_definition(['undefined'], 'Hash', allow_improvements: false)
      .to raise_error(/Foo#foo expected \["undefined"\], got: \["Hash"\]/)
  end

  it 'rejects a different type even when allowing improvements' do
    expect_definition(['String'], 'Hash', allow_improvements: true)
      .to raise_error(/Foo#foo expected \["String"\], got: \["Hash"\]/)
  end

  it 'rejects losing a type even when allowing improvements' do
    expect_definition(['self'], 'undefined', allow_improvements: true)
      .to raise_error(/Foo#foo expected \["self"\], got: \["undefined"\]/)
  end
end
