require 'spec_helper'

RSpec.describe Solargraph::Rails::Autoload do
  let(:api_map) { Solargraph::ApiMap.new }

  it "auto completes implicit nested classes" do
    load_string 'test1.rb', %(
      class Foo
        class Bar
          class Baz
            def run; end
          end
        end
      end
      Foo::Bar::Baz
    )

    expect(completion_at('test1.rb', [8, 6])).to include("Foo")
    expect(completion_at('test1.rb', [8, 11])).to include("Bar")
    expect(completion_at('test1.rb', [8, 16])).to include("Baz")

    load_string 'test1.rb', %(
      class Foo::Bar::Baz;
        def run; end
      end
      Foo::Bar::Baz
    )

    expect(completion_at('test1.rb', [4, 6])).to include("Foo")
    expect(completion_at('test1.rb', [4, 11])).to include("Bar")
    expect(completion_at('test1.rb', [4, 16])).to include("Baz")
  end
end
