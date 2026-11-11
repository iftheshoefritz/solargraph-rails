# frozen_string_literal: true

RSpec.describe Definitions do
  before { skip 'needs Solargraph::RbsMap::Conversions as a class' unless ExpectedTypes::SUPPORTED }

  let(:map) do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'probe.rbs'), <<~RBS)
        class HarnessProbe
          def boolish_method: () -> boolish
          def string_method: () -> String
        end
      RBS
      loader = RBS::EnvironmentLoader.new
      loader.add(path: Pathname.new(dir))
      pins = Solargraph::RbsMap::Conversions.new(loader: loader).pins
      Solargraph::ApiMap.new(pins: pins.select { |pin| pin.path.to_s.start_with?('HarnessProbe') })
    end
  end

  it 'matches an RBS alias in YAML against a method returning that alias, and only that' do
    message =
      begin
        described_class.new(map, 'HarnessProbe', 'harness/boolish').assert_matches_definitions
      rescue RuntimeError => e
        e.message
      end

    expect([message.to_s.include?('HarnessProbe#string_method'),
            message.to_s.include?('HarnessProbe#boolish_method')]).to eq([true, false])
  end
end
