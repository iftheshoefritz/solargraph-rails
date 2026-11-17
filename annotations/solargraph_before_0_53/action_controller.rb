module ActionController
  class Base < Metal
    # turbo-rails includes this from an ActiveSupport.on_load hook in its engine
    include ::Turbo::Native::Navigation
  end
end
