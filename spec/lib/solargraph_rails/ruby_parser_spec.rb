require 'solargraph_rails/ruby_parser'

RSpec.describe SolargraphRails::RubyParser do
  context 'callbacks' do
    it 'empty file calls nothing' do
      parser = SolargraphRails::RubyParser.new(file_contents: '')

      handler = ->(x) { }
      parser.on_comment(&handler)
      parser.on_class(&handler)
      parser.on_module(&handler)
      expect(handler).not_to receive(:call)

      parser.parse
    end

    context 'comments' do
      it 'passes content of comment without "#"' do
        parser = SolargraphRails::RubyParser.new(
          file_contents: "# a comment\n"
        )
        handler = proc { |x| expect(x).to eq('a comment') }
        parser.on_comment(&handler)

        expect(handler).to receive(:call).and_call_original

        parser.parse
      end

      it 'calls handler once for each comment' do
        parser = SolargraphRails::RubyParser.new(
          file_contents: "# a comment\n# another comment\n"
        )
        handler = proc {}
        parser.on_comment(&handler)

        expect(handler).to receive(:call).twice

        parser.parse
      end
    end

    context 'class declaration' do
      it 'passes correct class name' do
        parser = SolargraphRails::RubyParser.new(
          file_contents: "class X\nend"
        )
        handler = proc { |klass_name| expect(klass_name).to eq('X') }
        parser.on_class(&handler)

        expect(handler).to receive(:call).and_call_original

        parser.parse
      end

      it 'passes class name with superclass' do
        parser = SolargraphRails::RubyParser.new(
          file_contents: "class X < Y\nend"
        )
        handler = proc do |klass, superklass|
          expect(klass).to eq('X')
          expect(superklass).to eq('Y')
        end

        parser.on_class(&handler)

        expect(handler).to receive(:call).and_call_original

        parser.parse
      end

      it 'passes superklass with namespace' do
        parser = SolargraphRails::RubyParser.new(
          file_contents: "class X < Yabc::Zabc\nend"
        )
        handler = proc do |klass, superklass|
          expect(superklass).to eq('Yabc::Zabc')
        end

        parser.on_class(&handler)

        expect(handler).to receive(:call).and_call_original

        parser.parse

      end
    end

    context 'module declaration' do
      context 'standalone module' do
        it 'passes correct module name' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "module MyModule\n"
          )
          handler = proc { |mod| expect(mod).to eq('MyModule') }
          parser.on_module(&handler)

          expect(handler).to receive(:call).and_call_original

          parser.parse
        end

        it 'calls handler once for each module declaration' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "module MyModule\n  module MyModule2\n  end\nend"
          )
          handler = proc { }
          parser.on_module(&handler)

          expect(handler).to receive(:call).twice

          parser.parse
        end
      end

      context 'inline module and class' do
        it 'calls module handler with inline module name' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "class MyModule::MyClass\nend"
          )
          module_handler = proc { |mod| expect(mod).to eq('MyModule') }

          parser.on_module(&module_handler)

          expect(module_handler).to receive(:call).and_call_original

          parser.parse
        end

        it 'calls class handler with class name' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "class MyModule::MyClass\nend"
          )
          class_handler = proc { |klass| expect(klass).to eq('MyClass') }

          parser.on_class(&class_handler)

          expect(class_handler).to receive(:call).and_call_original

          parser.parse
        end

        it 'multiple inline module names' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "class MyModule1::MyModule2::MyModule3::MyClass\nend"
          )
          handler = proc { }

          parser.on_module(&handler)

          expect(handler).to receive(:call).exactly(3).times

          parser.parse
        end

        it 'does not process namespace in superclass' do
          parser = SolargraphRails::RubyParser.new(
            file_contents: "class MyModule1::MyClass < SuperNamespace::Superclass\nend"
          )
          handler = proc { }

          parser.on_module(&handler)

          expect(handler).to receive(:call).with('MyModule1')
          expect(handler).not_to receive(:call).with('SuperNamespace')

          parser.parse

        end
      end
    end
  end

  it 'line info' do
    parser = SolargraphRails::RubyParser.new(
      file_contents: "class X\n# a comment\n"
    )

    parser.on_class do |klass|
      expect(parser.current_line_number).to eq(0)
      expect(parser.current_line_length).to eq(7)
    end

    parser.on_comment do |comment|
      expect(parser.current_line_number).to eq(1)
      expect(parser.current_line_length).to eq(11)
    end

    parser.parse
  end
end
