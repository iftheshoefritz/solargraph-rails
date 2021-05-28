require 'solargraph/rails/files_loader'

RSpec.describe Solargraph::Rails::PinCreator do
  context 'non-ruby file' do
    it 'creates no pins' do
      expect(
        Solargraph::Rails::PinCreator.new(
          'nonruby.txt',
          'xyz$&*^'
        ).create_pins
      ).to eq([])
    end
  end

  context 'non-model ruby file' do
    it 'creates no pins' do
      expect(
        Solargraph::Rails::PinCreator.new(
          'non_model.rb',
          "# PORO\nclass NonModel\nend\n"
        ).create_pins
      ).to eq([])
    end
  end
end
