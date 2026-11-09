require 'spec_helper'

RSpec.describe Solargraph::Rails::Model do
  let(:api_map) { Solargraph::ApiMap.new }

  it 'generates methods for singular association' do
    load_string 'app/models/transaction.rb',
                <<~RUBY
      class Transaction < ActiveRecord::Base
        belongs_to :account
        has_one :category
      end
    RUBY

    assert_method(
      api_map,
      'Transaction#account',
      ['Account']
    ) do |pin|
      expect(pin.location.filename).to eq(
        File.expand_path('app/models/transaction.rb')
      )
      expect(pin.location.range.to_hash).to eq(
        { start: { line: 1, character: 0 }, end: { line: 1, character: 2 } }
      )
    end

    assert_method(api_map, 'Transaction#category', ['Category'])
  end

  it 'generates methods for association with custom class_name' do
    load_string 'app/models/transaction.rb',
                <<-RUBY
                class Transaction < ActiveRecord::Base
                  belongs_to :account, class_name: 'CustomAccount'
                end
                RUBY

    assert_method(
      api_map,
      'Transaction#account',
      ['CustomAccount']
    )
  end

  it 'generates methods for plural associations' do
    load_string 'app/models/account.rb',
                <<-RUBY
                class Account < ActiveRecord::Base
                  has_many :transactions
                  has_and_belongs_to_many :things
                end
                RUBY

    assert_method(
      api_map,
      'Account#transactions',
      ['Transaction::ActiveRecord_Relation']
    )
    assert_method(
      api_map,
      'Account#things',
      ['Thing::ActiveRecord_Relation']
    )
  end

  it 'exposes scopes as class methods' do
    load_string 'app/models/transaction.rb',
                <<-RUBY
                class Transaction < ActiveRecord::Base
                  scope :positive, ->() { where(foo: 'bar') }
                end
                RUBY

    assert_method(api_map, 'Transaction.positive', ['Transaction::ActiveRecord_Relation'])
    assert_method(api_map, 'Transaction::ActiveRecord_Relation#positive', ['Transaction::ActiveRecord_Relation'])
  end

  it 'exposes scopes as relation instance methods' do
    load_string 'app/models/person.rb',
      <<~RUBY
      class Person < ActiveRecord::Base
        scope :taller_than, ->(h) { where(height: h..) }
      end
      RUBY

    assert_method(
      api_map,
      'Person::ActiveRecord_Relation#taller_than',
      ['Person::ActiveRecord_Relation'],
      args: { h: 'undefined' }
    )
  end

  it 'handles primary_abstract_class without breaking' do
    expect do
      load_string 'app/models/application_record.rb',
                  <<-RUBY
                  class ApplicationRecord < ActiveRecord::Base
                    primary_abstract_class
                  end
                  RUBY
    end.not_to raise_error
  end

  it 'generates scope methods with parameters' do
    load_string 'app/models/person.rb',
                <<-RUBY
                class Person < ActiveRecord::Base
                  scope :taller_than,
                        ->(min_height) { where('height > ?', min_height) }
                end
                RUBY

    assert_method(
      api_map,
      'Person.taller_than',
      ['Person::ActiveRecord_Relation'],
      args: { min_height: 'undefined' }
    )
  end

  it 'does not generate methods for variable named scope' do
    load_string 'app/models/person.rb',
                <<-RUBY
                class Person < ActiveRecord::Base
                  def some_method
                    scope = Person.where(id: 0)
                    scope.count
                  end

                  scope :taller_than,
                        ->(min_height) { where('height > ?', min_height) }
                end
                RUBY

    # TODO: Does this test do the thing it says does?
    assert_method(
      api_map,
      'Person.taller_than',
      ['Person::ActiveRecord_Relation'],
      args: { min_height: 'undefined' }
    )
  end

  it 'exposes class methods as instance methods on relations', if: Solargraph::Rails::Delegate.supported? do
    load_string 'app/models/person.rb',
      <<~RUBY
      class Person < ActiveRecord::Base
        # @param h [Numeric]
        def self.taller_than(h)
          where(height: h..)
        end
      end
      RUBY

    assert_method(
      api_map,
      'Person::ActiveRecord_Relation#taller_than',
      ['Person::ActiveRecord_Relation'],
      args: { h: 'Numeric' }
    )
  end

  it 'binds the RBS query-method type parameters to the model and ActiveRecord::Base' do
    pending 'https://github.com/castwide/solargraph/pull/1344 and https://github.com/apiology/solargraph/pull/126'

    filename = nil
    map = rails_workspace do |root|
      root.write_file 'app/models/widget.rb', <<~RUBY
        class Widget < ActiveRecord::Base
        end
      RUBY

      filename = root.write_file 'app/models/widget_report.rb', <<~RUBY
        class WidgetReport
          def run
            model_ids = Widget.ids
            relation_ids = Widget.all.ids
            base_relation = ActiveRecord::Base.where(id: 1)
          end
        end
      RUBY
    end

    inferred = ->(line) { member_tags(map.clip_at(filename, [line, 6]).infer) }
    expect(inferred.call(2)).to eq(['Array<Integer>'])
    expect(inferred.call(3)).to eq(['Array<Integer>'])
    expect(inferred.call(4)).to eq(['ActiveRecord::Relation'])
  end
end
