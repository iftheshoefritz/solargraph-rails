require 'spec_helper'

RSpec.describe Solargraph::Rails::Annotate do
  before { Solargraph::Rails::Annotate.reset }

  let(:api_map) { Solargraph::ApiMap.new }

  it "reads `annotate' comments" do
    load_string 'app/models/my_model.rb',
                <<~RUBY
      #  id                        :integer          not null, primary key
      #  start_date                :date
      #  living_expenses           :decimal(, )
      #  less_deposits             :boolean          default(FALSE)
      #  notes                     :text
      #  name                      :string
      #  created_at                :datetime
      #  price                     :float
      class MyModel < ApplicationRecord
      end
    RUBY

    assert_public_instance_method(api_map, 'MyModel#id', ['Integer']) do |pin|
      expect(pin.location.range.to_hash).to eq(
        { start: { line: 0, character: 0 }, end: { line: 0, character: 68 } }
      )
    end

    assert_public_instance_method(api_map, 'MyModel#start_date', ['Date'])
    assert_public_instance_method(api_map, 'MyModel#start_date=', ['Date'],
                                  args: { value: 'Date' })
    assert_public_instance_method(
      api_map,
      'MyModel#living_expenses',
      ['BigDecimal']
    )
    assert_public_instance_method(api_map, 'MyModel#less_deposits', ['Boolean'])
    assert_public_instance_method(api_map, 'MyModel#notes', ['String'])
    assert_public_instance_method(api_map, 'MyModel#name', ['String'])
    assert_public_instance_method(
      api_map,
      'MyModel#created_at',
      ['ActiveSupport::TimeWithZone']
    )
    assert_public_instance_method(api_map, 'MyModel#price', ['BigDecimal'])
  end
end
