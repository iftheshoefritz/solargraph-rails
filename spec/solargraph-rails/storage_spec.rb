require "spec_helper"

RSpec.describe Solargraph::Rails::Storage do
  it "can auto-complete ActiveStorage" do
    map = use_workspace "./spec/rails7" do |root|
      root.write_file 'app/models/thing.rb', <<~EOS
        class Thing < ActiveRecord::Base
          has_one_attached :image
          has_many_attached :photos
        end

        Thing.new.image.att
        Thing.new.photos.att
      EOS

    end
    filename = File.expand_path('./app/models/thing.rb', './spec/rails7')
    expect(completion_at(filename, [5, 19], map)).to include("attach")
    expect(completion_at(filename, [6, 20], map)).to include("attach")
  end
end
