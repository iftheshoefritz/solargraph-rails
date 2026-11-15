# These mirror activerecord 7.2's RBS for Rails 7.0 and 7.1, whose
# gem_rbs_collection RBS (activerecord 7.0 and 7.1) lacks them. Remove
# once gem_rbs_collection backports them to activerecord 7.0 and 7.1.
module ActiveRecord
  module SignedId
    # @param expires_in [ActiveSupport::Duration, nil]
    # @param expires_at [Time, ActiveSupport::TimeWithZone, nil]
    # @param purpose [undefined]
    # @return [String]
    def signed_id(expires_in: nil, expires_at: nil, purpose: nil); end

    module ClassMethods
      def signed_id_verifier_secret; end

      def signed_id_verifier_secret=(value); end
    end
  end

  module Calculations
    # @overload pluck(column)
    #   @return [Array]
    # @overload pluck(*columns)
    #   @return [Array<Array>]
    def pluck(*column_names); end
  end
end
