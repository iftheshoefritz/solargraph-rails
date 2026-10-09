module Solargraph
  module Rails
    module LoadHooks
      # Classes each ActiveSupport.on_load hook runs on, from the
      # run_load_hooks call sites in Rails 7.0-8.1. Hooks run on the app, a
      # config object or an including class (e.g. :after_initialize) are left out.
      # https://github.com/search?q=repo%3Arails%2Frails+run_load_hooks&type=code
      CLASSES = {
        action_cable_channel: ['ActionCable::Channel::Base'],
        action_cable_channel_test_case: ['ActionCable::Channel::TestCase'],
        action_cable_connection: ['ActionCable::Connection::Base'],
        action_cable_connection_test_case: ['ActionCable::Connection::TestCase'],
        action_cable_test_case: ['ActionCable::TestCase'],
        action_controller: ['ActionController::Base', 'ActionController::API'],
        action_controller_api: ['ActionController::API'],
        action_controller_base: ['ActionController::Base'],
        action_controller_test_case: ['ActionController::TestCase'],
        action_dispatch_integration_test: ['ActionDispatch::IntegrationTest'],
        action_dispatch_request: ['ActionDispatch::Request'],
        action_dispatch_response: ['ActionDispatch::Response'],
        action_dispatch_system_test_case: ['ActionDispatch::SystemTestCase'],
        action_mailbox: ['ActionMailbox::Base'],
        action_mailbox_inbound_email: ['ActionMailbox::InboundEmail'],
        action_mailbox_record: ['ActionMailbox::Record'],
        action_mailbox_test_case: ['ActionMailbox::TestCase'],
        action_mailer: ['ActionMailer::Base'],
        action_mailer_test_case: ['ActionMailer::TestCase'],
        action_text_content: ['ActionText::Content'],
        action_text_encrypted_rich_text: ['ActionText::EncryptedRichText'],
        action_text_record: ['ActionText::Record'],
        action_text_rich_text: ['ActionText::RichText'],
        action_view: ['ActionView::Base'],
        action_view_test_case: ['ActionView::TestCase'],
        active_job: ['ActiveJob::Base'],
        active_job_continuable: ['ActiveJob::Continuable'],
        active_job_test_case: ['ActiveJob::TestCase'],
        active_model: ['ActiveModel::Model'],
        active_model_error: ['ActiveModel::Error'],
        active_model_secure_password: ['ActiveModel::SecurePassword'],
        active_model_translation: ['ActiveModel::Translation'],
        active_record: ['ActiveRecord::Base'],
        active_record_database_configurations: ['ActiveRecord::DatabaseConfigurations'],
        active_record_encryption: ['ActiveRecord::Encryption'],
        active_record_fixture_set: ['ActiveRecord::FixtureSet'],
        active_record_mysql2adapter: ['ActiveRecord::ConnectionAdapters::Mysql2Adapter'],
        active_record_postgresqladapter: ['ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'],
        active_record_sqlite3adapter: ['ActiveRecord::ConnectionAdapters::SQLite3Adapter'],
        active_record_trilogyadapter: ['ActiveRecord::ConnectionAdapters::TrilogyAdapter'],
        active_storage_attachment: ['ActiveStorage::Attachment'],
        active_storage_blob: ['ActiveStorage::Blob'],
        active_storage_record: ['ActiveStorage::Record'],
        active_storage_variant_record: ['ActiveStorage::VariantRecord'],
        active_support_test_case: ['ActiveSupport::TestCase'],
        message_pack: ['ActiveSupport::MessagePack']
      }.freeze

      # Solargraph < 0.56.2 keeps one processor per node type, so registering
      # there would replace its own :send processor.
      #
      # @return [Boolean]
      def self.supported?
        Solargraph::Parser::NodeProcessor.respond_to?(:deregister)
      end

      if supported?
        require_relative 'load_hooks/send_node'
        Solargraph::Parser::NodeProcessor.register(:send, SendNode)
      end
    end
  end
end
