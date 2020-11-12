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

  context 'attribute pin' do
    it 'has correct name'
    it 'has correct comments'
    it 'has correct location'
    it 'has correct closure'
    it 'is an instance variable'
    it 'is an attribute'
  end
end
