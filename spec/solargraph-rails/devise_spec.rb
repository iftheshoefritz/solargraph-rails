require 'spec_helper'

RSpec.describe Solargraph::Rails::Devise do
  it "includes devise modules" do
    filename = nil
    map = rails_workspace do |root|
      root.write_file 'app/models/awesome_user.rb', <<~RUBY
        class AwesomeUser < ActiveRecord::Base
          devise :registerable, :confirmable, :timeoutable, timeout_in: 12.hours
        end
      RUBY

      filename = root.write_file 'app/controllers/pages_controller.rb', <<~RUBY
        class PagesController < ApplicationController
          def index
            curr
            AwesomeUser.new.conf
          end
        end
      RUBY
    end

    expect(completion_at(filename, [3, 23], map)).to include("confirm")
  end
end
