require 'spec_helper'

RSpec.describe Solargraph::Rails::Schema do
  let(:schema) do
    <<~RUBY
      ActiveRecord::Schema.define(version: 2021_10_20_084658) do

        enable_extension "pg_trgm"

        create_table "accounts", force: :cascade do |t|
          t.jsonb "extra"
          t.decimal "balance", precision: 30, scale: 10, null: false
          t.integer "some_int"
          t.date "some_date"
          t.bigint "some_big_id", null: false
          t.string "name", null: false
          t.boolean "active"
          t.text "notes"
          t.inet "some_ip"
          t.datetime "created_at", null: false
          t.json "old_school_json"
          t.jsonb "new_school_json"
          t.uuid "uuid"
          t.citext "some_citext"
          t.binary "some_binary"
          t.timestamp "some_timestamp"

          t.check_constraint "balance > 0"
          t.index ["some_big_id"], name: "index_accounts_on_some_big_id", unique: true
        end
      end
    RUBY
  end

  before(:each) do
    # This feature has internal state that needs to be reset between test runs
    described_class.reset
  end

  it "generates methods based on schema" do
    map = use_workspace "./spec/rails7" do |root|
      root.write_file 'db/schema.rb', schema

      root.write_file 'app/models/account.rb', <<-RUBY
        class Account < ActiveRecord::Base
        end
      RUBY
    end

    assert_public_instance_method(map, "Account#extra", ["Hash"]) do |pin|
      expect(pin.location.range.to_hash).to eq({
        :start => { :line => 5, :character => 4 },
        :end => { :line => 5, :character => 19 }
      })
    end

    assert_public_instance_method(map, "Account#balance", ["BigDecimal"])
    assert_public_instance_method(map, "Account#balance=", ["BigDecimal"],
                                  args: { value: 'BigDecimal' })
    assert_public_instance_method(map, "Account#some_int", ["Integer"])
    assert_public_instance_method(map, "Account#some_date", ["Date"])
    assert_public_instance_method(map, "Account#some_big_id", ["Integer"])
    assert_public_instance_method(map, "Account#name", ["String"])
    assert_public_instance_method(map, "Account#active", ["Boolean"])
    assert_public_instance_method(map, "Account#notes", ["String"])
    assert_public_instance_method(map, "Account#some_ip", ["IPAddr"])
    assert_public_instance_method(map, "Account#uuid", ["String"])
    assert_public_instance_method(map, "Account#old_school_json", ["Hash"])
    assert_public_instance_method(map, "Account#new_school_json", ["Hash"])
    assert_public_instance_method(map, "Account#some_citext", ["String"])
    assert_public_instance_method(map, "Account#some_binary", ["String"])
    assert_public_instance_method(map, "Account#some_timestamp", ["ActiveSupport::TimeWithZone"])
  end

  it 'infers prefixed table name' do
    map = use_workspace "./spec/rails7" do |root|
      root.write_file 'db/schema.rb', <<-RUBY
        ActiveRecord::Schema.define(version: 2021_10_20_084658) do
          create_table "accounting_invoices", force: :cascade do |t|
            t.decimal "amount"
          end
        end
      RUBY

      root.write_file 'app/models/accounting/invoice.rb', <<-RUBY
        class Accounting::Invoice < ActiveRecord::Base
        end
      RUBY
    end

    assert_public_instance_method(map, "Accounting::Invoice#amount", ["BigDecimal"])
  end

  it 'falls back unprefixed tables even if model is namespaced' do
    map = use_workspace "./spec/rails7" do |root|
      root.write_file 'db/schema.rb', <<-RUBY
        ActiveRecord::Schema.define(version: 2021_10_20_084658) do
          create_table "invoices", force: :cascade do |t|
            t.decimal "amount"
          end
        end
      RUBY

      root.write_file 'app/models/accounting/invoice.rb', <<-RUBY
        class Accounting::Invoice < ActiveRecord::Base
        end
      RUBY
    end

    # resolves to accounts table
    assert_public_instance_method(map, "Accounting::Invoice#amount", ["BigDecimal"])
  end

  it 'uses explicit table name if defined' do
    map = use_workspace "./spec/rails7" do |root|
      root.write_file 'db/schema.rb', <<-RUBY
        ActiveRecord::Schema.define(version: 2021_10_20_084658) do
          create_table "bills", force: :cascade do |t|
            t.decimal "amount"
          end
        end
      RUBY

      root.write_file 'app/models/invoice.rb', <<-RUBY
        class Invoice < ActiveRecord::Base
          self.table_name = 'bills'
        end
      RUBY
    end

    assert_public_instance_method(map, 'Invoice#amount', ['BigDecimal'])
  end
end
