require 'spec_helper'

skip_reason = 'Missing required Solargraph pin type' unless Solargraph::Rails::Delegate.supported?

RSpec.describe Solargraph::Rails::Delegate, skip: skip_reason do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'generates delegate method pins' do
    load_string 'app/thing.rb', <<-RUBY
      class Thing
        delegate :one, :two, to: :foo
        # @return [Thing::Foo]
        def foo
          Foo.new
        end

        class Foo
          # @return [Integer]
          def one
            1
          end

          # @return [String]
          def two
            "two"
          end
        end
      end
    RUBY

    assert_method(api_map, 'Thing::Foo#one', ['Integer'])
    assert_method(api_map, 'Thing::Foo#two', ['String'])
    assert_method(api_map, 'Thing#one', ['Integer'])
    assert_method(api_map, 'Thing#two', ['String'])
  end

  describe 'as a :send node processor',
           skip: (described_class.processor? ? false : 'needs Solargraph >= 0.56.2 to chain :send processors') do
    # @param code [String]
    # @return [Array<Solargraph::Pin::DelegatedMethod>]
    def delegated_pins(code)
      Solargraph::SourceMap.load_string(code).pins.grep(Solargraph::Pin::DelegatedMethod)
    end

    it 'maps delegate to delegated instance methods' do
      pins = delegated_pins(<<~RUBY)
        class Foo
          delegate :bar, 'baz', to: :thing
        end
      RUBY
      expect(pins.map { |pin| [pin.path, pin.scope] }).to eq([['Foo#bar', :instance], ['Foo#baz', :instance]])
    end

    it 'maps delegate inside class << self to class methods' do
      pins = delegated_pins(<<~RUBY)
        class Foo
          class << self
            delegate :bar, to: :instance
          end
        end
      RUBY
      expect(pins.map { |pin| [pin.path, pin.scope] }).to eq([['Foo.bar', :class]])
    end

    it 'applies the prefix option' do
      pins = delegated_pins(<<~RUBY)
        class Foo
          delegate :bar, to: :thing, prefix: true
          delegate :baz, to: :thing, prefix: :other
          delegate :qux, to: :@thing, prefix: true
        end
      RUBY
      expect(pins.map(&:name)).to eq(%w[thing_bar other_baz])
    end

    it 'makes delegated methods private with private: true' do
      pins = delegated_pins(<<~RUBY)
        class Foo
          delegate :bar, to: :thing, private: true
          delegate :baz, to: :thing
        end
      RUBY
      expect(pins.map(&:visibility)).to eq(%i[private public])
    end

    it 'ignores delegate without a to: option or with a receiver' do
      pins = delegated_pins(<<~RUBY)
        class Foo
          delegate
          delegate :bar
          other.delegate :baz, to: :thing
        end
      RUBY
      expect(pins).to be_empty
    end

    it 'maps delegate of a splatted constant array' do
      pins = delegated_pins(<<~RUBY)
        module Foo
          METHODS = [:bar, :baz].freeze
          delegate(*METHODS, to: :all)
        end
      RUBY
      expect(pins.map(&:name)).to eq(%w[bar baz])
    end

    it 'maps each delegate onto the class that declares it' do
      load_string 'app/things.rb', <<~RUBY
        class First
          # @return [Integer]
          def count; end
        end

        class Second
          delegate :count, to: :first

          # @return [First]
          def first; end
        end
      RUBY

      assert_method(api_map, 'Second#count', ['Integer'])
    end

    it 'locates delegated methods at the delegate call' do
      load_string 'app/thing.rb', <<~RUBY
        class Thing
          delegate :one, to: :foo
        end
      RUBY
      expect(find_pin('Thing#one', api_map).location.range.start.line).to eq(1)
    end

    it 'maps one pin per delegated method in a workspace file' do
      load_string 'app/thing.rb', <<~RUBY
        class Thing
          delegate :one, to: :foo
        end
      RUBY
      expect(api_map.get_method_stack('Thing', 'one').length).to eq(1)
    end

    it 'infers the return type of an instance variable delegation' do
      load_string 'app/thing.rb', <<~RUBY
        class Thing
          def initialize
            # @type [Array<String>]
            @items = []
          end

          delegate :size, to: :@items
        end
      RUBY
      assert_method(api_map, 'Thing#size', ['Integer'])
    end

    it 'infers the return type of a method delegated to the class' do
      pending 'https://github.com/apiology/solargraph/pull/155'

      load_string 'app/thing.rb', <<~RUBY
        class Thing
          # @return [Integer]
          def self.total; end

          delegate :total, to: :class
        end
      RUBY
      expect(api_map.get_method_stack('Thing', 'total').first.typify(api_map).to_s).to eq('Integer')
    end
  end
end
