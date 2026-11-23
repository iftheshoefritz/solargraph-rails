require 'spec_helper'

# Loads the Rails workspace once for every example, as loading takes a while
module RoutesSpecWorkspace
  extend Helpers

  ROUTES = <<~RUBY.freeze
    Rails.application.routes.draw do
      resources :profiles, :posts
      resource :profile
      root 'posts#index'
      root 'admin/posts#index'
      root 'posts#find_post'
      resources :comments
      namespace :admin do
        resources :posts
      end
      controller :profiles do
      end
      resources :application
      get 'latest', to: 'posts#index'
      get 'feed' => 'admin/posts#index'
      match 'all', to: 'posts#index', via: :get
      root to: 'admin/posts#index'
      get 'private', to: 'posts#find_post'
    end
  RUBY

  # @return [Array(Solargraph::ApiMap, Hash{Symbol => String})] the map and the written files
  def self.load
    @load ||= begin
      files = {}
      map = rails_workspace do |root|
        files[:posts] = root.write_file 'app/controllers/posts_controller.rb', <<~RUBY
          class PostsController < ApplicationController
            def index; end

            private

            def find_post; end
          end
        RUBY
        files[:admin_posts] = root.write_file 'app/controllers/admin/posts_controller.rb', <<~RUBY
          class Admin::PostsController < ApplicationController
            def index; end
          end
        RUBY
        files[:profiles] = root.write_file 'app/controllers/profiles_controller.rb', <<~RUBY
          class ProfilesController < ApplicationController
          end
        RUBY
        files[:routes] = root.write_file 'config/routes/definitions.rb', ROUTES
      end
      [map, files]
    end
  end
end

RSpec.describe Solargraph::Rails::Routes do
  let(:map) { RoutesSpecWorkspace.load[0] }
  let(:files) { RoutesSpecWorkspace.load[1] }

  before do
    skip 'needs Solargraph::Pin::FactoryParameter' unless described_class.supported?
  end

  # @param line [Integer]
  # @param word [String] a literal on that line
  # @return [Array<Solargraph::Pin::Base>]
  def definitions_of(line, word)
    column = RoutesSpecWorkspace::ROUTES.lines[line].index(word) + 1
    definitions_at(files[:routes], [line, column], map)
  end

  # Before 0.62.0 Solargraph discards the only signature of a method that
  # takes a block when the call passes none, so `resources :posts` has no
  # parameters to match the literal against.
  def skip_unless_blockless_routes_resolve
    skip 'blockless calls lose their signature' if Gem::Version.new(Solargraph::VERSION) < Gem::Version.new('0.62.0')
  end

  # @return [Array(Symbol, Integer)] the file and line of each definition
  def locations_of(line, word)
    definitions_of(line, word).map do |pin|
      [files.key(pin.location.filename), pin.location.range.start.line]
    end
  end

  it 'goes from resources to their controllers' do
    skip_unless_blockless_routes_resolve

    expect(locations_of(1, ':profiles')).to eq([[:profiles, 0]])
    expect(locations_of(1, ':posts')).to contain_exactly([:posts, 0], [:admin_posts, 0])
  end

  it 'goes from a singular resource to its plural controller' do
    skip_unless_blockless_routes_resolve

    expect(locations_of(2, ':profile')).to eq([[:profiles, 0]])
  end

  it 'goes from a root route to its action' do
    expect(locations_of(3, "'posts#index'")).to eq([[:posts, 1]])
  end

  it 'goes from a root route to the action of a namespaced controller' do
    expect(locations_of(4, "'admin/posts#index'")).to eq([[:admin_posts, 1]])
  end

  it 'does not treat private methods as actions' do
    expect(definitions_of(5, "'posts#find_post'")).to be_empty
  end

  it 'ignores routes to unknown controllers' do
    expect(definitions_of(6, ':comments')).not_to include(be_a(Solargraph::Pin::FactoryParameter))
  end

  it 'ignores ApplicationController' do
    expect(definitions_of(12, ':application')).not_to include(be_a(Solargraph::Pin::FactoryParameter))
  end

  it 'goes from resources in a namespace block to their controllers' do
    skip_unless_nested_routes_resolve

    expect(locations_of(8, ':posts')).to contain_exactly([:posts, 0], [:admin_posts, 0])
  end

  it 'goes from a namespace to the controllers in it' do
    skip_unless_nested_routes_resolve

    expect(locations_of(7, ':admin')).to eq([[:admin_posts, 0]])
  end

  it 'goes from a controller scope to its controller' do
    skip_unless_nested_routes_resolve

    expect(locations_of(10, ':profiles')).to eq([[:profiles, 0]])
  end

  it 'goes from the to: of a verb route to its action' do
    skip_unless_keyword_routes_resolve

    expect(locations_of(13, "'posts#index'")).to eq([[:posts, 1]])
  end

  it 'goes from a hash pair verb route to its action' do
    skip_unless_keyword_routes_resolve

    expect(locations_of(14, "'admin/posts#index'")).to eq([[:admin_posts, 1]])
  end

  it 'goes from the to: of a match route to its action' do
    skip_unless_keyword_routes_resolve

    expect(locations_of(15, "'posts#index'")).to eq([[:posts, 1]])
  end

  it 'goes from the to: of a root route to its action' do
    skip_unless_keyword_routes_resolve

    expect(locations_of(16, "'admin/posts#index'")).to eq([[:admin_posts, 1]])
  end

  it 'does not treat private methods as verb route actions' do
    expect(definitions_of(17, "'posts#find_post'")).to be_empty
  end

  it 'maps no controllers without Solargraph::Pin::FactoryParameter' do
    allow(described_class).to receive(:supported?).and_return(false)

    expect(described_class.instance.process(map.source_map(files[:posts]))).to be_empty
  end
end
