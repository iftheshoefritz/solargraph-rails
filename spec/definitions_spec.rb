# frozen_string_literal: true

RSpec.describe Definitions do
  before { skip 'needs Solargraph::RbsMap::Conversions as a class' unless ExpectedTypes::SUPPORTED }

  it 'matches an RBS alias in YAML against a method returning that alias, and only that' do
    message = Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'probe.rbs'), <<~RBS)
        class HarnessProbe
          def boolish_method: () -> boolish
          def string_method: () -> String
        end
      RBS
      definitions_file = File.join(dir, 'boolish.yml')
      File.write(definitions_file, <<~YAML)
        "#boolish_method":
          types:
          - boolish
        "#string_method":
          types:
          - boolish
      YAML
      loader = RBS::EnvironmentLoader.new
      loader.add(path: Pathname.new(dir))
      pins = Solargraph::RbsMap::Conversions.new(loader: loader).pins
      map = Solargraph::ApiMap.new(pins: pins.select { |pin| pin.path.to_s.start_with?('HarnessProbe') })

      described_class.new(map, 'HarnessProbe', 'boolish', definitions_file: definitions_file)
                     .assert_matches_definitions
    rescue RuntimeError => e
      e.message
    end

    expect([message.to_s.include?('HarnessProbe#string_method'),
            message.to_s.include?('HarnessProbe#boolish_method')]).to eq([true, false])
  end
end
