root "posts#index"
resources :posts do
  member do
    get :preview
  end
  collection do
    get :search
  end
  get :archive, on: :member
  get :drafts, on: :collection
  resources :comments, only: [:index, :show]
end
resource :profile, except: :destroy
resources :photos, only: [:index, :show]
resource :user, only: [:index]
resources :members, only: [:index]
resources :authors, shallow: true do
  resources :books
end
namespace :admin do
  root "dashboard#show"
  resources :users, only: :index
end
scope as: :legacy do
  resources :tokens, only: :index
end
scope module: :billing do
  resources :invoices, only: :index
end
scope path: "/v2" do
  resources :reports, only: :index
end
resources :articles, as: :stories, only: [:index, :show]
get "search", to: "search#index", as: :site_search
get "photos/featured"
get "photos/:id/raw" => "photos#raw"
get "ignored", to: "pages#ignored", as: nil
resources :news, only: [:index, :show]
direct :homepage do
  "https://rubyonrails.org"
end
mount Blog::Engine, at: "/blog", as: :blog
concern :reviewable do
  resources :reviews, only: :index
end
resources :products, concerns: :reviewable, only: :show
resources(*ROUTED)
%w[a b].each { |name| resources name }
resources dynamic_name
get "elsewhere", to: "search#other", as: :site_search
concern :looping do
  resources :loops, only: :index
  concerns :looping
end
concerns :looping
draw :extras
root "pages#landing", as: :landing_root
