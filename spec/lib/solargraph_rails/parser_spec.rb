require 'solargraph_rails/files_loader'

RSpec.describe SolargraphRails::Parser do
  context 'non-ruby file'
  context 'non-model ruby file'
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
  context 'model with annotations'
  context 'descendant of ApplicationRecord'
  context 'descendant of ActiveRecord::Base'
  context 'with a leading # frozen_string_literal'
  context 'attribute pin' do
    it 'has correct name'
    it 'has correct comments'
    it 'has correct location'
    it 'has correct closure'
    it 'is an instance variable'
    it 'is an attribute'
  end
end
