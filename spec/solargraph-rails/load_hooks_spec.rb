require 'spec_helper'

RSpec.describe Solargraph::Rails::LoadHooks do
  describe 'CLASSES' do
    let(:classes) { described_class::CLASSES }

    it 'maps hook names to class names' do
      expect(classes).to all(match([be_a(Symbol), all(be_a(String))]))
    end

    it 'maps :action_controller to both controller base classes' do
      expect(classes[:action_controller]).to eq(['ActionController::Base', 'ActionController::API'])
    end

    it 'maps :active_record to ActiveRecord::Base' do
      expect(classes[:active_record]).to eq(['ActiveRecord::Base'])
    end

    it 'leaves out hooks that do not run on a class' do
      expect(classes.keys).not_to include(:after_initialize, :action_cable, :i18n)
    end
  end

  describe 'mapping mixins in ActiveSupport.on_load blocks',
           skip: (described_class.supported? ? false : 'needs Solargraph >= 0.56.2 to chain :send processors') do
    # @param code [String]
    # @return [Array<Array(String, String, String)>] reference type, namespace and module of each mixin
    def mixins_for(code)
      Solargraph::SourceMap.load_string(code).pins
                           .grep(Solargraph::Pin::Reference)
                           .grep_v(Solargraph::Pin::Reference::Require)
                           .map { |pin| [pin.class.name.split('::').last, pin.namespace, pin.name] }
    end

    it 'maps include onto the class the hook runs on' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:active_record) do
          include Mixin
        end
      RUBY
      expect(refs).to include(%w[Include ActiveRecord::Base Mixin])
    end

    it 'maps extend and prepend' do
      refs = mixins_for(<<~RUBY)
        ::ActiveSupport.on_load(:action_view) do
          extend Mixin
          prepend Other
        end
      RUBY
      expect(refs).to include(%w[Extend ActionView::Base Mixin], %w[Prepend ActionView::Base Other])
    end

    it 'maps every module in one include' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:action_controller_base) do
          include First, Second
        end
      RUBY
      expect(refs).to include(%w[Include ActionController::Base First], %w[Include ActionController::Base Second])
    end

    it 'maps a hook that runs on several classes onto each of them' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:action_controller) do
          include Mixin
        end
      RUBY
      expect(refs).to include(%w[Include ActionController::Base Mixin], %w[Include ActionController::API Mixin])
    end

    it 'maps send(:include) and self.extend' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:active_record) do
          send :include, First
          self.extend Second
        end
      RUBY
      expect(refs).to include(%w[Include ActiveRecord::Base First], %w[Extend ActiveRecord::Base Second])
    end

    it 'maps mixins called on the block parameter' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:active_record) do |base|
          base.include First
          base.send(:extend, Second)
        end
      RUBY
      expect(refs).to include(%w[Include ActiveRecord::Base First], %w[Extend ActiveRecord::Base Second])
    end

    it 'maps hooks registered inside a class body and method' do
      refs = mixins_for(<<~RUBY)
        module Engine
          class Railtie
            def self.setup
              ActiveSupport.on_load(:action_mailer) { include Mixin }
            end
          end
        end
      RUBY
      expect(refs).to include(%w[Include ActionMailer::Base Mixin])
    end

    it 'leaves hooks it does not know alone' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:i18n) do
          include Mixin
        end
      RUBY
      expect(refs.map { |ref| ref[1] }).not_to include('I18n')
    end

    it 'leaves on_load calls on other receivers alone' do
      refs = mixins_for(<<~RUBY)
        Other.on_load(:active_record) do
          include Mixin
        end
      RUBY
      expect(refs.map { |ref| ref[1] }).not_to include('ActiveRecord::Base')
    end

    it 'leaves mixins on other receivers in the block alone' do
      refs = mixins_for(<<~RUBY)
        ActiveSupport.on_load(:active_record) do |base|
          Other.include First
          other.include Second
        end
      RUBY
      expect(refs.map { |ref| ref[1] }).not_to include('ActiveRecord::Base')
    end

    it 'adds the mixed-in methods to the classes' do
      api_map = Solargraph::ApiMap.new
      load_string_into(api_map, 'app/lib/responders.rb', <<~RUBY)
        module ActionController
          class Base; end
          class API; end
        end

        module Responders
          module RespondWith
            def respond_with; end
          end

          ActiveSupport.on_load(:action_controller) do
            include Responders::RespondWith
          end
        end
      RUBY

      expect(find_pin('ActionController::Base#respond_with', api_map)).not_to be_nil
      expect(find_pin('ActionController::API#respond_with', api_map)).not_to be_nil
    end

    # @param api_map [Solargraph::ApiMap]
    # @param filename [String]
    # @param code [String]
    # @return [void]
    def load_string_into(api_map, filename, code)
      api_map.map(Solargraph::Source.load_string(code, filename))
    end
  end
end
