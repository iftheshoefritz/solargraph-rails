require 'solargraph/rails/files_loader'

RSpec.describe 'Methods based on association declarations' do
  context 'model without associations' do
    it 'creates no pins' do
      expect(
        Solargraph::Rails::PinCreator.new(
          'association_pins.rb',
          'class MyModel < ApplicationRecord; end'
        ).create_pins
      ).to eq([])
    end
  end

  context 'model with associations' do
    context 'belongs_to' do
      before do
        contents = <<-FILE
          class MyModel < ApplicationRecord
            belongs_to :other_model
          end
        FILE

        @pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      context 'attribute reader' do
        it 'has correct name' do
          expect(@pin_creator.create_pins.map(&:name)).to include('other_model')
        end

        context 'location' do
          it 'has correct position' do
            range = @pin_creator
                      .create_pins
                      .select { |pin| pin.name == 'other_model' }
                      .first
                      .location
                      .range

            expect(range.start.line).to eq(1)
            expect(range.start.column).to eq(0)
            expect(range.ending.line).to eq(1)
            expect(range.ending.column).to eq(34)
          end

          it 'has correct filename' do
            expect(
              @pin_creator
                .create_pins
                .select { |pin| pin.name == 'other_model' }
                .first
                .location
                .filename
            ).to eq('files/my_file/my_model.rb')
          end
        end

        it 'has correct closure' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_model' }
              .first
              .closure
              .name
          ).to eq('MyModel')
        end

        it 'has correct type' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_model' }
              .first
              .return_type
              .to_s
          ).to eq('OtherModel')
        end

        it 'is an instance method' do
          expect(@pin_creator.create_pins.first.scope).to eq(:instance)
        end
      end
    end

    context 'has_many' do
      before do
        contents = <<-FILE
          class MyModel < ApplicationRecord
            has_many :other_models
          end
        FILE

        @pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      context 'attribute reader' do
        it 'has correct name' do
          expect(@pin_creator.create_pins.map(&:name)).to include('other_models')
        end

        context 'location' do
          it 'has correct position' do
            range = @pin_creator
                      .create_pins
                      .select { |pin| pin.name == 'other_models' }
                      .first
                      .location
                      .range

            expect(range.start.line).to eq(1)
            expect(range.start.column).to eq(0)
            expect(range.ending.line).to eq(1)
            expect(range.ending.column).to eq(33)
          end

          it 'has correct filename' do
            expect(
              @pin_creator
                .create_pins
                .select { |pin| pin.name == 'other_models' }
                .first
                .location
                .filename
            ).to eq('files/my_file/my_model.rb')
          end
        end

        it 'has correct closure' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_models' }
              .first
              .closure
              .name
          ).to eq('MyModel')
        end

        it 'has correct type' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_models' }
              .first
              .return_type
              .to_s
          ).to eq('ActiveRecord::Associations::CollectionProxy<OtherModel>')
        end

        it 'is an instance method' do
          expect(@pin_creator.create_pins.first.scope).to eq(:instance)
        end
      end
    end

    context 'has_one' do
      before do
        contents = <<-FILE
          class MyModel < ApplicationRecord
            has_one :other_model
          end
        FILE

        @pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      context 'attribute reader' do
        it 'has correct name' do
          expect(@pin_creator.create_pins.map(&:name)).to include('other_model')
        end

        context 'location' do
          it 'has correct position' do
            range = @pin_creator
                      .create_pins
                      .select { |pin| pin.name == 'other_model' }
                      .first
                      .location
                      .range

            expect(range.start.line).to eq(1)
            expect(range.start.column).to eq(0)
            expect(range.ending.line).to eq(1)
            expect(range.ending.column).to eq(31)
          end

          it 'has correct filename' do
            expect(
              @pin_creator
                .create_pins
                .select { |pin| pin.name == 'other_model' }
                .first
                .location
                .filename
            ).to eq('files/my_file/my_model.rb')
          end
        end

        it 'has correct closure' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_model' }
              .first
              .closure
              .name
          ).to eq('MyModel')
        end

        it 'has correct type' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_model' }
              .first
              .return_type
              .to_s
          ).to eq('OtherModel')
        end

        it 'is an instance method' do
          expect(@pin_creator.create_pins.first.scope).to eq(:instance)
        end
      end
    end

    context 'has_and_belongs_to_many' do
      before do
        contents = <<-FILE
          class MyModel < ApplicationRecord
            has_and_belongs_to_many :other_models
          end
        FILE

        @pin_creator = Solargraph::Rails::PinCreator.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      context 'attribute reader' do
        it 'has correct name' do
          expect(@pin_creator.create_pins.map(&:name)).to include('other_models')
        end

        context 'location' do
          it 'has correct position' do
            range = @pin_creator
                      .create_pins
                      .select { |pin| pin.name == 'other_models' }
                      .first
                      .location
                      .range

            expect(range.start.line).to eq(1)
            expect(range.start.column).to eq(0)
            expect(range.ending.line).to eq(1)
            expect(range.ending.column).to eq(48)
          end

          it 'has correct filename' do
            expect(
              @pin_creator
                .create_pins
                .select { |pin| pin.name == 'other_models' }
                .first
                .location
                .filename
            ).to eq('files/my_file/my_model.rb')
          end
        end

        it 'has correct closure' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_models' }
              .first
              .closure
              .name
          ).to eq('MyModel')
        end

        it 'has correct type' do
          expect(
            @pin_creator
              .create_pins
              .select { |pin| pin.name == 'other_models' }
              .first
              .return_type
              .to_s
          ).to eq('ActiveRecord::Associations::CollectionProxy<OtherModel>')
        end

        it 'is an instance method' do
          expect(@pin_creator.create_pins.first.scope).to eq(:instance)
        end
      end
    end
  end
end
