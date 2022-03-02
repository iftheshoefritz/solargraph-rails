require 'spec_helper'

RSpec.describe Solargraph::Rails::Devise do
  it "includes devise modules in rails5" do
    map = use_workspace "./spec/rails5" do |root|
      root.write_file 'app/models/awesome_user.rb', <<~RUBY
        class AwesomeUser < ActiveRecord::Base
          devise :registerable, :confirmable, :timeoutable, timeout_in: 12.hours
        end
      RUBY

      root.write_file 'app/controllers/pages_controller.rb', <<~RUBY
        class PagesController < ApplicationController
          def index
            curr
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    filename = './app/controllers/pages_controller.rb'
    expect(completion_at(filename, [3, 23], map)).to include("confirm")
  end

  it "includes devise modules in rails6" do
    map = use_workspace "./spec/rails6" do |root|
      root.write_file 'app/models/awesome_user.rb', <<~RUBY
        class AwesomeUser < ActiveRecord::Base
          devise :registerable, :confirmable, :timeoutable, timeout_in: 12.hours
        end
      RUBY

      root.write_file 'app/controllers/pages_controller.rb', <<~RUBY
        class PagesController < ApplicationController
          def index
            curr
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    filename = './app/controllers/pages_controller.rb'
    expect(completion_at(filename, [3, 23], map)).to include("confirm")
  end
end
