module ActiveStorage
  # Provides the class-level DSL for declaring an Active Record model's attachments.
  module Attached
    module Model
      extend ActiveSupport::Concern

      # mutate class_methods
      module ClassMethods
        # Specifies the relation between a single attachment and the model.
        #
        #   class User < ApplicationRecord
        #     has_one_attached :avatar
        #   end
        #
        # There is no column defined on the model side, Active Storage takes
        # care of the mapping between your records and the attachment.
        #
        # To avoid N+1 queries, you can include the attached blobs in your query like so:
        #
        #   User.with_attached_avatar
        #
        # Under the covers, this relationship is implemented as a +has_one+ association to a
        # ActiveStorage::Attachment record and a +has_one-through+ association to a
        # ActiveStorage::Blob record. These associations are available as +avatar_attachment+
        # and +avatar_blob+. But you shouldn't need to work with these associations directly in
        # most circumstances.
        #
        # The system has been designed to having you go through the ActiveStorage::Attached::One
        # proxy that provides the dynamic proxy to the associations and factory methods, like +attach+.
        #
        # If the +:dependent+ option isn't set, the attachment will be purged
        # (i.e. destroyed) whenever the record is destroyed.
        #
        # If you need the attachment to use a service which differs from the globally configured one,
        # pass the +:service+ option. For instance:
        #
        #   class User < ActiveRecord::Base
        #     has_one_attached :avatar, service: :s3
        #   end
        #
        # If you need to enable +strict_loading+ to prevent lazy loading of attachment,
        # pass the +:strict_loading+ option. You can do:
        #
        #   class User < ApplicationRecord
        #     has_one_attached :avatar, strict_loading: true
        #   end
        #

        # @param name [String, Symbol]
        # @param dependent [Symbol] the action to take on the attachment when the record is destroyed
        # @param strict_loading [Boolean]
        # @param service [String, Symbol, nil] the service to use for the attachment
        # @return [void]
        def has_one_attached(name, dependent: :default, service: nil, strict_loading: false); end

        # Specifies the relation between multiple attachments and the model.
        #
        #   class Gallery < ApplicationRecord
        #     has_many_attached :photos
        #   end
        #
        # There are no columns defined on the model side, Active Storage takes
        # care of the mapping between your records and the attachments.
        #
        # To avoid N+1 queries, you can include the attached blobs in your query like so:
        #
        #   Gallery.where(user: Current.user).with_attached_photos
        #
        # Under the covers, this relationship is implemented as a +has_many+ association to a
        # ActiveStorage::Attachment record and a +has_many-through+ association to a
        # ActiveStorage::Blob record. These associations are available as +photos_attachments+
        # and +photos_blobs+. But you shouldn't need to work with these associations directly in
        # most circumstances.
        #
        # The system has been designed to having you go through the ActiveStorage::Attached::Many
        # proxy that provides the dynamic proxy to the associations and factory methods, like +#attach+.
        #
        # If the +:dependent+ option isn't set, all the attachments will be purged
        # (i.e. destroyed) whenever the record is destroyed.
        #
        # If you need the attachment to use a service which differs from the globally configured one,
        # pass the +:service+ option. For instance:
        #
        #   class Gallery < ActiveRecord::Base
        #     has_many_attached :photos, service: :s3
        #   end
        #
        # If you need to enable +strict_loading+ to prevent lazy loading of attachments,
        # pass the +:strict_loading+ option. You can do:
        #
        #   class Gallery < ApplicationRecord
        #     has_many_attached :photos, strict_loading: true
        #   end
        #
        # @param name [String, Symbol]
        # @param dependent [Symbol] the action to take on the attachment when the record is destroyed
        # @param strict_loading [Boolean]
        # @param service [String, Symbol, nil] the service to use for the attachment
        # @return [void]
        def has_many_attached(name, dependent: :default, service: nil, strict_loading: false); end

        # @return [void]
        def attachment_changes(); end

        # @return [Boolean]
        def changed_for_autosave?; end

        # @param lock [BasicObject]
        # @return [self]
        def reload(lock = false); end
      end
    end
  end
end
