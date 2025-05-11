require 'spec_helper'

# Validate against here if there's a question: https://api.rubyonrails.org/v7.1.0/
RSpec.describe 'Rails 7 API' do
  it 'it provides Rails controller api' do
    map =
      use_workspace './spec/rails7' do |root|
        root.write_file 'app/controllers/things_controller.rb', <<~EOS
          class ThingsController < ActionController::Base
            res
            def index
              re
            end
          end
        EOS
      end

    filename = File.expand_path('./app/controllers/things_controller.rb', './spec/rails7')
    expect(completion_at(filename, [1, 4], map)).to include('rescue_from')

    expect(completion_at(filename, [3, 5], map)).to include(
      'respond_to',
      'redirect_to',
      'response',
      'request',
      'render'
    )
  end

  it 'can auto-complete inside routes', skip: 'not working' do
    map =
      use_workspace './spec/rails7' do |root|
        root.write_file 'config/routes.rb', <<~EOS
        Rails.application.routes.draw do
          res
          resource :things do
            res
          end
        end
      EOS
      end

    filename = File.expand_path('./config/routes.rb', './spec/rails7')
    expect(completion_at(filename, [1, 5], map)).to include('resources')
    expect(completion_at(filename, [3, 7], map)).to include('resources')
  end

  it 'can auto-complete inside mailers' do
    map =
      use_workspace './spec/rails7' do |root|
        root.write_file 'app/mailers/test_mailer.rb', <<~EOS
          class TestMailer < ActionMailer::Base
            defa
            def welcome_email
              ma
            end
          end
        EOS
      end

    filename = File.expand_path('./app/mailers/test_mailer.rb', './spec/rails7')
    expect(completion_at(filename, [1, 6], map)).to include('default')
    expect(completion_at(filename, [3, 6], map)).to include('mail')
  end

  it 'can auto-complete inside migrations' do
    map =
      use_workspace './spec/rails7' do |root|
        root.write_file 'db/migrate/20130502114652_create_things.rb', <<~EOS
          class CreateThings < ActiveRecord::Migration[7.0]
            def self.up
              crea
            end

            def change
              crea
              create_table :things do |t|
                t.col
              end
              change_table :things do |t|
                t.col
              end
              create_join_table :things do |t|
                t.col
              end
            end
          end
        EOS
      end

    filename = File.expand_path('./db/migrate/20130502114652_create_things.rb', './spec/rails7')
    expect(completion_at(filename, [2, 7], map)).to include('create_table')
    expect(completion_at(filename, [6, 7], map)).to include('create_table')
    expect(completion_at(filename, [8, 10], map)).to include('column')
    expect(completion_at(filename, [11, 10], map)).to include('column')
    expect(completion_at(filename, [14, 10], map)).to include('column')
  end

  it 'provides completions for ActiveJob::Base' do
    map = use_workspace './spec/rails7'

    assert_matches_definitions(
      map,
      'ActiveJob::Base',
      'rails7/activejob'
    )
  end

  it 'understands Object methods from activesupport' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'Object',
      'acts_like?',
      scope: :instance,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.first).to be_a(Solargraph::Pin::Method)
  end

  # ActiveRecord::Base extends ActiveRecord::ConnectionHandling
  it 'understands ActiveRecord::ConnectionHandling methods from activesupport' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'ActiveRecord::Base',
      'connecting_to',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.first).to be_a(Solargraph::Pin::Method)
  end

  # ActiveRecord::Base extends ::ActiveRecord::Inheritance::ClassMethods
  it 'understands ActiveRecord::Inheritance::ClassMethods methods from activesupport' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'ActiveRecord::Base',
      'abstract_class',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.first).to be_a(Solargraph::Pin::Method)
  end

  it 'understands which gem rails is' do
    doc_map = Solargraph::DocMap.new(['rails'], [])
    expect(doc_map.gemspecs.map(&:name)).to include('rails')
  end

  it 'understands Class methods from activesupport used in active_job' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'ActiveJob::Base',
      'class_attribute',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.first).to be_a(Solargraph::Pin::Method)
  end

  it 'picks useful definition of Module#attr_internal_accessor' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'Module',
      'attr_internal_accessor',
      scope: :instance,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.map(&:class).uniq).to eq([Solargraph::Pin::Method])
    expect(methods.map(&:return_type).map(&:to_s).uniq).to eq(['void'])
  end

  it 'provides completions for ActionDispatch::Routing::Mapper' do
    map = use_workspace './spec/rails7'

    assert_matches_definitions(
      map,
      'ActionDispatch::Routing::Mapper',
      'rails7/routes'
    )
  end

  # ActiveRecord::Base extends [ActiveRecord]::Translation, which
  # includes ActiveModel::Translation, which has human_attribute_name
  # as an instance method
  it "uses solargraph-rails' overridden definition of ActiveRecord::QueryMethods#where" do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7' do |injector|
      injector.write_file 'app/models/person.rb', <<~EOS
        class Person < ActiveRecord::Base; end
      EOS
    end
    methods = api_map.get_method_stack(
      'Person',
      'where',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.map(&:class).uniq).to eq([Solargraph::Pin::Method])
    method = methods.first
    expect(method.signatures.map(&:return_type).map(&:to_s)).to eq(["ActiveRecord::QueryMethods::WhereChain<Person::ActiveRecord_Relation>", "Person::ActiveRecord_Relation"])
  end

  # ActiveRecord::Base extends [ActiveRecord]::Translation, which
  # includes ActiveModel::Translation, which has human_attribute_name
  # as an instance method
  it 'follows extends and includes to find ActiveRecord::Base.human_attribute_name' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'ActiveRecord::Base',
      'human_attribute_name',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
  end

  it 'follows extends and includes to find ActiveRecord::Base.sanitize_sql' do
    # @type [Solargraph::ApiMap]
    api_map = use_workspace './spec/rails7'
    methods = api_map.get_method_stack(
      'ActiveRecord::Base',
      'sanitize_sql',
      scope: :class,
      visibility: %i[public protected private]
    )
    expect(methods).not_to be_empty
    expect(methods.map(&:return_type).flat_map(&:items).map(&:rooted_tag)).to eq(['nil', '::String'])
  end

  it 'provides completions for ActiveRecord::Base' do
    map = use_workspace './spec/rails7'
    assert_matches_definitions(map, 'ActiveRecord::Base', 'rails7/activerecord')
  end

  it 'provides completions for ActionController::Base' do
    map = use_workspace './spec/rails7'
    assert_matches_definitions(
      map,
      'ActionController::Base',
      'rails7/actioncontroller'
    )
  end

  context 'auto-completes ActiveSupport core extensions' do
    Dir
      .glob('spec/definitions/rails7/core/*.yml')
      .each do |path|
      name = File.basename(path).split('.').first

      it "core/#{name}" do
        map = use_workspace './spec/rails7'

        assert_matches_definitions(map, name, "rails7/core/#{name}")
      end
    end
  end
end
