require 'spec_helper'

skip_reason = 'Missing required Solargraph pin type' unless Solargraph::Rails::Delegate.supported?

RSpec.describe Solargraph::Rails::Delegate, skip: skip_reason do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'generates delegate method pins' do
    load_string 'app/thing.rb', <<-RUBY
      class Thing
        delegate :one, :two, to: :foo
        def foo
          Foo.new
        end

        class Foo
          def one
            1
          end

          def two
            "two"
          end
        end
      end
    RUBY

    assert_public_instance_method(api_map, 'Thing#one', ['Integer'])
    assert_public_instance_method(api_map, 'Thing#two', ['String']) do |pin|
      expect(pin.location.range.to_hash).to eq(
        start: { line: 1, character: 0 },
        end: { line: 1, character: 8 }
      )
    end
  end
end
