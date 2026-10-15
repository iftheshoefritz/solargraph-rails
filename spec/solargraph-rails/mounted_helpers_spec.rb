require 'spec_helper'

RSpec.describe Solargraph::Rails::MountedHelpers do
  describe '.scan', skip: (if defined?(Solargraph::Parser::ParserGem::NodeMethods)
                             false
                           else
                             'needs Solargraph::Parser::ParserGem'
                           end) do
    it 'finds helpers that define_mounted_helper adds' do
      scan = described_class.scan(<<~RUBY)
        initializer :define_main_app_helper do |app|
          app.routes.define_mounted_helper(:main_app)
        end
      RUBY

      expect(scan.helpers).to eq(['main_app'])
    end

    it 'finds classes whose on_load hooks include mounted_helpers' do
      scan = described_class.scan(<<~RUBY)
        initializer "action_controller.set_configs" do |app|
          ActiveSupport.on_load(:action_controller) do
            include app.routes.mounted_helpers
          end
        end
      RUBY

      expect(scan.targets).to eq(['ActionController::Base', 'ActionController::API'])
    end

    it 'ignores helper names that are not literal symbols' do
      scan = described_class.scan('routes.define_mounted_helper(name)')

      expect(scan.helpers).to be_empty
    end

    it 'ignores mounted_helpers included outside on_load hooks' do
      scan = described_class.scan(<<~RUBY)
        Class.new(ActionView::Base) do
          include routes.mounted_helpers
        end
      RUBY

      expect(scan.targets).to be_empty
    end

    it 'finds nothing in an empty file' do
      scan = described_class.scan('')

      expect([scan.helpers, scan.targets]).to eq([[], []])
    end

    it 'ignores on_load hooks not called on ActiveSupport' do
      scan = described_class.scan(<<~RUBY)
        on_load(:action_controller) { include routes.mounted_helpers }
        Other.on_load(:action_controller) { include routes.mounted_helpers }
        ActiveSupport.on_load(hook) { include routes.mounted_helpers }
      RUBY

      expect(scan.targets).to be_empty
    end
  end

  it 'types main_app in controllers from the Rails gems',
     skip: (if described_class.supported?
              false
            else
              'needs Solargraph to expose the gems it loaded'
            end) do
    filename = nil
    map =
      rails_workspace do |root|
        filename = root.write_file 'app/controllers/things_controller.rb', <<~RUBY
          class ThingsController < ActionController::Base
            def index
              main_app
            end
          end
        RUBY
      end

    expect(map.clip_at(filename, [2, 6]).infer.to_s).to eq('ActionDispatch::Routing::RoutesProxy')
    expect(map.get_method_stack('ActionController::API', 'main_app').map { |pin| pin.typify(map).to_s })
      .to eq(['ActionDispatch::Routing::RoutesProxy'])
  end
end
