require 'spec_helper'

RSpec.describe Solargraph::Rails::Autoload do
  let(:api_map) { Solargraph::ApiMap.new }

  it "auto completes explicit nested classes" do
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
  end

  it "auto completes implicit nested classes" do
    load_string 'test2.rb', %(
      class Fop::Bap::Ban
        def rux; end
      end
      Fop::Bap::Ban
    )

    expect(completion_at('test2.rb', [4, 6])).to include("Fop")
    expect(completion_at('test2.rb', [4, 11])).to include("Bap")
    expect(completion_at('test2.rb', [4, 16])).to include("Ban")
  end
end
