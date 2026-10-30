require 'spec_helper'

RSpec.describe Solargraph::Rails::Devise do
  it "includes devise modules" do
    # Solargraph 0.62.0 does not extend classes defined in gems with the
    # ClassMethods of the ActiveSupport::Concern modules they include:
    # https://github.com/castwide/solargraph/pull/1469 removed the convention
    # that did; https://github.com/castwide/solargraph/pull/1476 restores it.
    # Keyed on the exact version, so a later release that is still broken
    # fails here rather than being skipped silently.
    skip "ActiveSupport::Concern class methods missing; see castwide/solargraph#1476" if Solargraph::VERSION == "0.62.0"

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
