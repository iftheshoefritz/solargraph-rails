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
    assert_method(api_map, 'Thing#two', ['String']) do |pin|
      expect(pin.location.range.to_hash).to eq(
        start: { line: 14, character: 10 },
        end: { line: 16, character: 13 }
      )
    end
  end
end
