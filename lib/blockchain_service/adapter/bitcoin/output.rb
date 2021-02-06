module BlockchainService
  module Adapter
    class Bitcoin::Output
      attr_reader :raw_json, :tx

      def initialize(raw_json, tx)
        @raw_json = raw_json
        @tx = tx
        inspect
      end

      # :nocov:
      def inspect
        recipient = addresses.count == 1 ? addresses.first : addresses
        "#<BlockchainService::Bitcoin::Output recipient=#{recipient}, amount=#{amount}, tx=#{tx.id}>"
      end
      # :nocov:

      [:value, :n, :scriptPubKey].each do |attr|
        define_method(attr) do
          raw_json.fetch(attr.to_s)
        end
      end

      alias_method :script_pub_key, :scriptPubKey
      alias_method :amount, :value

      # :nocov:
      def multisig?
        addresses.count > 1
      end

      def addresses
        script_pub_key.fetch("addresses", [])
      end
      # :nocov:
    end
  end
end
