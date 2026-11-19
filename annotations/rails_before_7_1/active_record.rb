module ActiveRecord
  module SignedId
    # A String, or a Proc returning one
    # @return [String, Proc, nil]
    def signed_id_verifier_secret; end

    module ClassMethods
      # A String, or a Proc returning one
      # @return [String, Proc, nil]
      def signed_id_verifier_secret; end

      # @param value [String, Proc, nil]
      # @return [String, Proc, nil]
      def signed_id_verifier_secret=(value); end
    end
  end
end
