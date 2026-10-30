require "spec_helper"

RSpec.describe Solargraph::Rails::Storage do
  it "can auto-complete ActiveStorage" do
    # Solargraph 0.62.0 does not extend classes defined in gems with the
    # ClassMethods of the concerns they include:
    # https://github.com/castwide/solargraph/pull/1469 removed the convention
    # that did; https://github.com/castwide/solargraph/pull/1476 restores it.
    # Keyed on the exact version, so a later release that is still broken
    # fails here rather than being skipped silently.
    skip "concern class methods missing; see castwide/solargraph#1476" if Solargraph::VERSION == "0.62.0"

    filename = nil
    map = rails_workspace do |root|
      filename = root.write_file 'app/models/thing.rb', <<~EOS
        class Thing < ActiveRecord::Base
          has_one_attached :image
          has_many_attached :photos
        end

        Thing.new.image.att
        Thing.new.photos.att
      EOS
    end

    expect(completion_at(filename, [5, 19], map)).to include("attach")
    expect(completion_at(filename, [6, 20], map)).to include("attach")
  end
end
