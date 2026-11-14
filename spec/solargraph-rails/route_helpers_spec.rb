require 'spec_helper'

RSpec.describe Solargraph::Rails::RouteHelpers do
  # The routes and their callers are fixture files, drawn from config/routes.rb of spec/rails8; spec/rails7 links to
  # them. Loading the Rails app takes seconds, so the examples share one library.

  # @return [Hash{String => String, Symbol, nil}] each helper with the start of the routes line creating it, or nil
  #   when Rails defines no such helper
  def self.helpers
    {
      'root_path' => 'root "posts#index"',
      'landing_root_path' => 'root "pages#landing"',
      'posts_path' => 'resources :posts do',
      'posts_url' => 'resources :posts do',
      'post_path' => 'resources :posts do',
      'new_post_path' => 'resources :posts do',
      'edit_post_url' => 'resources :posts do',
      'preview_post_path' => 'get :preview',
      'search_posts_path' => 'get :search',
      'archive_post_path' => 'get :archive, on: :member',
      'drafts_posts_path' => 'get :drafts, on: :collection',
      'post_comments_path' => 'resources :comments',
      'post_comment_path' => 'resources :comments',
      'edit_post_comment_path' => nil,
      'profile_path' => 'resource :profile',
      'new_profile_path' => 'resource :profile',
      'edit_profile_path' => 'resource :profile',
      'profiles_path' => nil,
      'photos_path' => 'resources :photos',
      'photo_path' => 'resources :photos',
      'new_photo_path' => nil,
      'edit_photo_path' => nil,
      'user_path' => nil,
      'users_path' => nil,
      'new_user_path' => nil,
      'edit_user_path' => nil,
      'members_path' => 'resources :members',
      'member_path' => nil,
      'new_member_path' => nil,
      'edit_member_path' => nil,
      'author_books_path' => 'resources :books',
      'new_author_book_path' => 'resources :books',
      'book_path' => 'resources :books',
      'edit_book_path' => 'resources :books',
      'author_book_path' => nil,
      'admin_root_path' => 'root "dashboard#show"',
      'admin_users_path' => 'resources :users',
      'legacy_tokens_path' => 'resources :tokens',
      'tokens_path' => nil,
      'invoices_path' => 'resources :invoices',
      'billing_invoices_path' => nil,
      'reports_path' => 'resources :reports',
      'v2_reports_path' => nil,
      'stories_path' => 'resources :articles',
      'story_path' => 'resources :articles',
      'articles_path' => nil,
      'site_search_path' => 'get "search"',
      'photos_featured_path' => 'get "photos/featured"',
      'ignored_path' => nil,
      'news_index_path' => 'resources :news',
      'news_path' => 'resources :news',
      'homepage_path' => 'direct :homepage',
      'homepage_url' => 'direct :homepage',
      'blog_path' => 'mount Blog::Engine',
      'blog' => 'mount Blog::Engine',
      'product_reviews_path' => 'resources :reviews',
      'loops_path' => 'resources :loops',
      'audits_path' => :extras
    }
  end

  def self.root
    File.expand_path("../rails#{ENV.fetch('MATRIX_RAILS_VERSION').split('.').first}", __dir__)
  end

  def self.library
    @library ||= Solargraph::Library.load(root).tap do |library|
      library.map!
      library.catalog
    end
  end

  def library
    self.class.library
  end

  def path(relpath)
    File.join(self.class.root, relpath)
  end

  # @param relpath [String]
  # @param call [String] the text of the line, whose first character the cursor is on
  # @return [Array<Solargraph::Pin::Base>]
  def definitions(relpath, call)
    lines = File.readlines(path(relpath))
    line = lines.index { |text| text.strip == call }
    library.definitions_at(path(relpath), line, lines[line].index(call))
  end

  def routes_file
    'config/routes/route_helpers.rb'
  end

  # @param needle [String]
  # @param code [String] the routes file
  # @return [Integer] the 0-based line of the routes file starting with the needle
  def routes_line(needle, code = File.read(path(routes_file)))
    code.lines.index { |text| text.strip.start_with?(needle) }
  end

  # @return [Array(String, Integer)] the file and line a pin is at
  def place(pin)
    [pin.location.filename, pin.location.range.start.line]
  end

  def controller_definition(helper)
    definitions('app/controllers/route_helpers_controller.rb', helper).first
  end

  describe 'helper names' do
    helpers.each do |helper, needle|
      if needle.nil?
        it "defines no #{helper}" do
          expect(controller_definition(helper)).to be_nil
        end
      else
        it "defines #{helper} at the route that creates it" do
          expected = if needle == :extras
                       [path('config/routes/extras.rb'), 0]
                     else
                       [path(routes_file), routes_line(needle)]
                     end

          expect(place(controller_definition(helper))).to eq(expected)
        end
      end
    end
  end

  describe 'hover' do
    it 'documents the verbs, path pattern and controller#action of the helper\'s path' do
      pin = controller_definition('post_path')

      expect(pin.documentation).to include('GET', '/posts/:id(.:format)', 'posts#show')
      expect(pin.documentation).to include('DELETE', 'posts#destroy')
    end

    it 'documents only the routes the helper\'s own route call defines' do
      expect(controller_definition('root_path').documentation).to include('posts#index')
      expect(controller_definition('root_path').documentation).not_to include('pages#landing')
      expect(controller_definition('landing_root_path').documentation).to include('pages#landing')
      expect(controller_definition('landing_root_path').documentation).not_to include('posts#index')
    end

    it 'takes the required path segments and options' do
      pin = controller_definition('post_comment_path')

      expect(pin.parameters.map(&:name)).to eq(%w[post_id id options])
      expect(pin.parameters.map(&:decl)).to eq(%i[optarg optarg kwrestarg])
    end

    it 'returns a String' do
      expect(controller_definition('edit_post_url').return_type.to_s).to eq('String')
    end

    it 'routes namespaced and scoped resources to their module' do
      expect(controller_definition('admin_users_path').documentation).to include('admin/users#index')
      expect(controller_definition('invoices_path').documentation).to include('/invoices(.:format) billing/invoices#index')
      expect(controller_definition('reports_path').documentation).to include('/v2/reports(.:format)')
    end

    it 'types a mounted engine\'s helper as a route proxy' do
      expect(controller_definition('blog').return_type.to_s).to eq('ActionDispatch::Routing::RoutesProxy')
    end
  end

  describe 'callers' do
    it 'resolves helpers in helper modules' do
      expect(place(definitions('app/helpers/route_helpers_helper.rb', 'post_path').first))
        .to eq([path(routes_file), routes_line('resources :posts do')])
    end

    it 'resolves helpers in mailers' do
      expect(definitions('app/mailers/route_helpers_mailer.rb', 'posts_url').first&.name).to eq('posts_url')
    end

    it 'resolves helpers in integration tests' do
      expect(definitions('spec/route_helpers_flow_test.rb', 'posts_path').first&.name).to eq('posts_path')
    end

    it 'resolves helpers on Rails.application.routes.url_helpers' do
      lines = File.readlines(path('lib/route_helpers_client.rb'))
      column = lines[2].index('posts_path')

      expect(library.definitions_at(path('lib/route_helpers_client.rb'), 2, column).first&.name).to eq('posts_path')
    end

    it 'does not resolve mounted engine proxies on Rails.application.routes.url_helpers' do
      lines = File.readlines(path('lib/route_helpers_client.rb'))
      column = lines[3].index('blog')

      expect(library.definitions_at(path('lib/route_helpers_client.rb'), 3, column)).to be_empty
    end

    it 'does not resolve helpers in models' do
      expect(definitions('app/models/route_helpers_record.rb', 'posts_path')).to be_empty
    end

    it 'does not resolve helpers in plain objects' do
      expect(definitions('lib/route_helpers_client.rb', 'posts_path')).to be_empty
    end
  end

  it 'refreshes the helpers when the routes file changes' do
    filename = path(routes_file)
    edited = File.read(filename).sub('draw :extras', "draw :extras\nresources :tags")
    expect(controller_definition('tags_path')).to be_nil

    library.attach(Solargraph::Source.load_string(edited, filename, 1))

    expect(place(controller_definition('tags_path'))).to eq([filename, routes_line('resources :tags', edited)])
  ensure
    library.attach(Solargraph::Source.load_string(File.read(filename), filename, 2))
  end
end
