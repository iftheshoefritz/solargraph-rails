require 'solargraph_rails/files_loader'

RSpec.describe SolargraphRails::Parser do
  context 'non-ruby file' do
    it 'creates no pins' do
      expect(
        SolargraphRails::Parser.new(
          'nonruby.txt',
          'xyz$&*^'
        ).parse
      ).to eq([])
    end
  end

  context 'non-model ruby file' do
    it 'creates no pins' do
      expect(
        SolargraphRails::Parser.new(
          'non_model.rb',
          "# PORO\nclass NonModel\nend\n"
        ).parse
      ).to eq([])
    end
  end

  context 'model without annotations' do
    it 'creates no pins' do
      expect(
        SolargraphRails::Parser.new(
          'unannotated_model.rb',
          'class UnannotatedModel < AppliationRecord; end'
        ).parse
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

        @parser = SolargraphRails::Parser.new(
          'files/my_file/my_model.rb',
          contents
        )
      end

      it 'has correct name' do
        expect(@parser.parse.first.name).to eq('id')
      end

      context 'location' do
        it 'has correct filename' do
          expect(@parser.parse.first.location.filename).to eq('files/my_file/my_model.rb')
        end

        it 'has correct position' do
          range = @parser.parse.first.location.range
          expect(range.start.line).to eq(0)
          expect(range.start.column).to eq(0)
          expect(range.ending.line).to eq(0)
          expect(range.ending.column).to eq(78)
        end
      end

      it 'has correct closure' do
        expect(@parser.parse.first.closure.name).to eq('MyModel')
      end

      it 'has correct comments' do
        expect(@parser.parse.first.comments).to eq(
          '@return [Integer]'
        )
      end

      it 'is an instance variable' do
        expect(@parser.parse.first.scope).to eq(:instance)
      end

      it 'is an attribute' do
        expect(@parser.parse.first.attribute?).to eq(true)
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
          class MyModel < ApplicationRecord
        FILE

        pins = SolargraphRails::Parser.new('app/models/my_model.rb', contents).parse
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
        SolargraphRails::Parser.new(
          'my_model.rb',
          contents
        ).parse.count
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
        SolargraphRails::Parser.new(
          'my_model.rb',
          contents
        ).parse.count
      ).to eq(1)
    end
  end

  context 'descendant of ApplicationRecord' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          SolargraphRails::Parser.new(
            'my_model.rb',
            <<-FILE
              #  start_date  :date
              class MyModel < ApplicationRecord
              end
            FILE
          ).parse.count
        ).to eq(1)
      end
    end
  end

  context 'descendant of ActiveRecord::Base' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          SolargraphRails::Parser.new(
            'my_model.rb',
            <<-FILE
              #  start_date  :date
              class MyModel < ActiveRecord::Base
              end
            FILE
          ).parse.count
        ).to eq(1)
      end
    end
  end

  context 'with a leading # frozen_string_literal' do
    context 'with one annotation' do
      it 'has one pin' do
        expect(
          SolargraphRails::Parser.new(
            'my_model.rb',
            <<-FILE
              # frozen_string_literal: true

              #  start_date  :date
              class MyModel < ActiveRecord::Base
              end
            FILE
          ).parse.count
        ).to eq(1)
      end
    end
  end
end
