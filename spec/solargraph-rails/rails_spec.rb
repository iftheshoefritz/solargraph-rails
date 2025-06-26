require 'spec_helper'

RSpec.describe 'Rails API completion' do
  filename = nil
  it 'it provides Rails controller api' do
    map =
      rails_workspace do |root|
        filename = root.write_file 'app/controllers/things_controller.rb', <<~EOS
          class ThingsController < ActionController::Base
            res
            def index
              re
            end
          end
        EOS
      end

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
    filename = nil
    map =
      rails_workspace do |root|
        filename = root.write_file 'config/routes.rb', <<~EOS
        Rails.application.routes.draw do
          res
          resource :things do
            res
          end
        end
      EOS
      end

    expect(completion_at(filename, [1, 5], map)).to include('resources')
    expect(completion_at(filename, [3, 7], map)).to include('resources')
  end

  it 'can auto-complete inside mailers' do
    filename = nil
    map =
      rails_workspace do |root|
        filename = root.write_file 'app/mailers/test_mailer.rb', <<~EOS
        class TestMailer < ActionMailer::Base
          defa
          def welcome_email
            ma
          end
        end
      EOS
      end

    expect(completion_at(filename, [1, 6], map)).to include('default')
    expect(completion_at(filename, [3, 6], map)).to include('mail')
  end

  xit 'understands mattr methods' do
    map = rails_workspace
    # assert_class_method(map, 'ActiveJob::QueuePriority::ClassMethods.default_priority', ['undefined'])
    assert_class_method(map, 'ActiveJob::QueueName::ClassMethods.default_queue_name', ['undefined'])
    # assert_public_instance_method(map, 'ActiveJob::QueueName::ClassMethods#default_queue_name', ['undefined'])
  end


  xit 'can auto-complete inside migrations' do
    filename = nil
    map =
      rails_workspace do |root|
        filename = root.write_file 'db/migrate/20130502114652_create_things.rb', <<~EOS
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

    expect(completion_at(filename, [2, 7], map)).to include('create_table')
    expect(completion_at(filename, [6, 7], map)).to include('create_table')
    expect(completion_at(filename, [8, 10], map)).to include('column')
    expect(completion_at(filename, [11, 10], map)).to include('column')
    expect(completion_at(filename, [14, 10], map)).to include('column')
  end

  it 'provides completions for ActiveJob::Base' do
    map = rails_workspace

    assert_matches_definitions(
      map,
      'ActiveJob::Base',
      'activejob'
    )
  end

  it 'provides completions for Rails::Application' do
    map = rails_workspace

    assert_matches_definitions(
      map,
      'Rails::Application',
      'application'
    )
  end

  it 'provides completions for ActionDispatch::Routing::Mapper' do
    map = rails_workspace

    assert_matches_definitions(
      map,
      'ActionDispatch::Routing::Mapper',
      'routes'
    )
  end

  it 'provides completions for ActiveRecord::Base' do
    map = rails_workspace

    assert_matches_definitions(map, 'ActiveRecord::Base', 'activerecord')
  end

  it 'provides completions for ActionController::Base' do
    map = rails_workspace
    assert_matches_definitions(
      map,
      'ActionController::Base',
      'actioncontroller'
    )
  end

  # https://github.com/iftheshoefritz/solargraph-rails/issues/124
  xit 'understands ActiveRecord::Base#validation_context' do
    map = rails_workspace
    assert_method(map, 'ActiveRecord::Base#validation_context', ['undefined'])
  end

  # defined as self method in 'included' block in ActiveRecord::Core
  xit 'understands ActiveRecord::Base.current_preventing_writes' do
    map = rails_workspace
    assert_method(map, 'ActiveRecord::Base.current_preventing_writes', ['undefined'])
  end

  it 'understands ActiveJob::Base#logger' do
    map = rails_workspace
    assert_method(map, 'ActiveJob::Base#logger', ['undefined'])
  end

  context 'auto-completes ActiveSupport core extensions' do
    Dir
      .glob('spec/definitions/core/*.yml')
      .each do |path|
      name = File.basename(path).split('.').first

      it "core/#{name}" do
        map = rails_workspace

        assert_matches_definitions(map, name, "core/#{name}")
      end
    end
  end
end
