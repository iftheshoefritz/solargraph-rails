require 'solargraph/rails/files_loader'

RSpec.describe 'Attributes based on annotate' do
  context 'model without annotations' do
    it 'creates no pins' do
      expect(
        Solargraph::Rails::PinCreator.new(
          'unannotated_model.rb',
          'class UnannotatedModel < AppliationRecord; end'
        ).create_pins
      ).to eq([])
    end
  end

  context 'model with annotations' do
    context 'attribute pin' do
      before do
        contents = <<-FILE
          #  id                        :integer          not null, primary key
          class MyModel < ApplicationRecord
        FILE

        @pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      it 'has correct name' do
        expect(@pin_creator.create_pins.first.name).to eq('id')
      end

      context 'location' do
        it 'has correct filename' do
          expect(@pin_creator.create_pins.first.location.filename).to eq('files/my_file/my_model.rb')
        end

        it 'has correct position' do
          range = @pin_creator.create_pins.first.location.range
          expect(range.start.line).to eq(0)
          expect(range.start.column).to eq(0)
          expect(range.ending.line).to eq(0)
          expect(range.ending.column).to eq(77)
        end
      end

      it 'has correct closure' do
        expect(@pin_creator.create_pins.first.closure.name).to eq('MyModel')
      end

      it 'has correct comments' do
        expect(@pin_creator.create_pins.first.comments).to eq(
          '@return [Integer]'
        )
      end

      it 'is an instance variable' do
        expect(@pin_creator.create_pins.first.scope).to eq(:instance)
      end

      it 'is an attribute' do
        expect(@pin_creator.create_pins.first.attribute?).to eq(true)
      end
    end

    context 'types' do
      it 'can ignore string column length info in brackets' do
        contents = <<-FILE
          #  name            :string(255)
          class MyModel < ApplicationRecord
        FILE

        pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
        expect(pin_creator.create_pins.first.return_type.to_s).to eq('String')
      end

      it 'can ignore decimal precision info' do
        contents = <<-FILE
          #  cost_of_attendance       :decimal(, )
          class MyModel < ApplicationRecord
        FILE

        pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
        expect(pin_creator.create_pins.first.return_type.to_s).to eq('BigDecimal')
      end
    end

    context 'multiple annotations' do
      it 'types are correct' do
        contents = <<-FILE
          #  id                        :integer          not null, primary key
          #  start_date                :date
          #  living_expenses           :decimal(, )
          #  less_deposits             :boolean          default(FALSE)
          #  notes                     :text
          #  name                      :string
          #  created_at                :datetime
          #  price                     :float
          class MyModel < ApplicationRecord
        FILE

        pins = Solargraph::Rails::PinCreator.new('app/models/my_model.rb', contents).create_pins
        attrs = pins.each_with_object({}) do |pin, memo|
          memo[pin.name] = pin.return_type.to_s
        end
        expect(attrs['id']).to eq('Integer')
        expect(attrs['start_date']).to eq('Date')
        expect(attrs['living_expenses']).to eq('BigDecimal')
        expect(attrs['less_deposits']).to eq('Boolean')
        expect(attrs['notes']).to eq('String')
        expect(attrs['name']).to eq('String')
        expect(attrs['created_at']).to eq('ActiveSupport::TimeWithZone')
        expect(attrs['price']).to eq('Float')
      end
    end
  end

  context 'model with malformed annotations' do

    it 'if all are mangled, it returns nothing' do
      contents = <<-FILE
        #  i:integer          not null, primary key
        #  s:date
        #  l:decimal(, )
        #  l:boolean          default(FALSE)
        #  n:text
        #  c:datetime
        #class MyModel < ApplicationRecord
      FILE

      expect(
        Solargraph::Rails::PinCreator.new(
          'my_model.rb',
          contents
        ).create_pins.count
      ).to eq(0)
    end

    it 'valid annotation amongst other comments' do
      contents = <<-FILE
        #  l:boolean          default(FALSE)
        #  n:text
        #  c:datetime
        #  start_date  :date
        # other comments
        #
        class MyModel < ApplicationRecord
      FILE

      expect(
        Solargraph::Rails::PinCreator.new(
          'my_model.rb',
          contents
        ).create_pins.count
      ).to eq(1)
    end
  end

  context 'descendant of ApplicationRecord' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          Solargraph::Rails::PinCreator.new(
            'my_model.rb',
            <<-FILE
              #  start_date  :date
              class MyModel < ApplicationRecord
              end
            FILE
          ).create_pins.count
        ).to eq(1)
      end
    end
  end

  context 'descendant of ActiveRecord::Base' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          Solargraph::Rails::PinCreator.new(
            'my_model.rb',
            <<-FILE
              #  start_date  :date
              class MyModel < ActiveRecord::Base
              end
            FILE
          ).create_pins.count
        ).to eq(1)
      end
    end
  end

  context 'with a leading # frozen_string_literal' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          Solargraph::Rails::PinCreator.new(
            'my_model.rb',
            <<-FILE
              # frozen_string_literal: true

              #  start_date  :date
              class MyModel < ActiveRecord::Base
              end
            FILE
          ).create_pins.count
        ).to eq(1)
      end
    end
  end

  context 'nested class and module' do
    it 'Module::Class' do
      pins = Solargraph::Rails::PinCreator.new(
        'my_model.rb',
        <<-FILE
        # frozen_string_literal: true

        #  start_date  :date
        class MyModule::MyModel < ActiveRecord::Base
        end
        FILE
      ).create_pins

      attr = pins.first
      expect(
        attr.closure.path
      ).to eq(
        'MyModule::MyModel'
      )
    end

    it 'module and class on separate lines' do
      pins = Solargraph::Rails::PinCreator.new(
        'my_model.rb',
        <<-FILE
        # frozen_string_literal: true

        #  start_date  :date
        module MyModule
          class MyModel < ActiveRecord::Base
          end
        end
        FILE
      ).create_pins

      attr = pins.first
      expect(
        attr.closure.path
      ).to eq(
        'MyModule::MyModel'
      )
    end

    it 'more than one module' do
      pins = Solargraph::Rails::PinCreator.new(
        'my_model.rb',
        <<-FILE
        # frozen_string_literal: true

        #  start_date  :date
        module MyModule
          module MyOtherModule
            class MyModel < ActiveRecord::Base
            end
          end
        end
        FILE
      ).create_pins

      attr = pins.first
      expect(
        attr.closure.path
      ).to eq(
        'MyModule::MyOtherModule::MyModel'
      )
    end

    it 'inline and standalone module names' do
      pins = Solargraph::Rails::PinCreator.new(
        'my_model.rb',
        <<-FILE
        # frozen_string_literal: true

        #  start_date  :date
        module MyModule
          module MyOtherModule
            class MyInlineModule::MyModel < ActiveRecord::Base
            end
          end
        end
        FILE
      ).create_pins

      attr = pins.first
      expect(
        attr.closure.path
      ).to eq(
        'MyModule::MyOtherModule::MyInlineModule::MyModel'
      )
    end
  end
end
