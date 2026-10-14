require 'spec_helper'

RSpec.describe Solargraph::Rails::QueryGenerics do
  let(:base) { Solargraph::Pin::Namespace.new(name: 'ActiveRecord::Base') }
  let(:model) { Solargraph::Pin::Namespace.new(name: 'User') }
  let(:relation) { Solargraph::Pin::Namespace.new(name: 'User::ActiveRecord_Relation') }

  # @param pin [Solargraph::Pin::Reference]
  def describe_pin(pin)
    [pin.class, pin.closure.path, pin.name, pin.generic_values]
  end

  describe '.binds_by_position?' do
    it 'reports whether this Solargraph binds generics by position' do
      expect(described_class.send(:binds_by_position?)).to be(true).or be(false)
    end
  end

  context 'when supported' do
    before { allow(described_class).to receive(:supported?).and_return(true) }

    it 'extends ActiveRecord::Base with ClassMethods bound to self' do
      pins = described_class.base_pins([model, base])

      expect(pins.map { |pin| describe_pin(pin) }).to eq(
        [[Solargraph::Pin::Reference::Extend, 'ActiveRecord::Base',
          'ActiveRecord::Base::ClassMethods', ['self', 'ActiveRecord::Relation', 'Integer']]]
      )
    end

    it 'adds nothing without an ActiveRecord::Base pin' do
      expect(described_class.base_pins([model])).to eq([])
    end

    it 'binds a model and its relation to the model' do
      pins = described_class.model_pins(model, relation)

      expect(pins.map { |pin| describe_pin(pin) }).to eq(
        [
          [Solargraph::Pin::Reference::Extend, 'User',
           'ActiveRecord::Base::ClassMethods', ['User', 'User::ActiveRecord_Relation', 'Integer']],
          [Solargraph::Pin::Reference::Include, 'User::ActiveRecord_Relation',
           'ActiveRecord::Relation::Methods', %w[User Integer]]
        ]
      )
    end
  end

  context 'when unsupported' do
    before { allow(described_class).to receive(:supported?).and_return(false) }

    it 'adds no ActiveRecord::Base pins' do
      expect(described_class.base_pins([base])).to eq([])
    end

    it 'adds no model pins' do
      expect(described_class.model_pins(model, relation)).to eq([])
    end
  end
end
