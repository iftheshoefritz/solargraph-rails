module ActiveRecord
  module SignedId
    # @return [String, Proc, nil]
    def signed_id_verifier_secret; end

    module ClassMethods
      # @return [String, Proc, nil]
      def signed_id_verifier_secret; end

      # @param value [String, Proc, nil]
      # @return [String, Proc, nil]
      def signed_id_verifier_secret=(value); end
    end
  end
end
