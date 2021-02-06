module BlockchainService
  module Adapter
    class Bitcoin::TX
      attr_reader :raw_json, :block

      def initialize(raw_json, block)
        @raw_json = raw_json
        @block = block
        inspect
      end

      # :nocov:
      def inspect
        "#<#{self.class} id=#{txid} block=#{block.id}>"
      end
      # :nocov:

      [:txid, :hash, :version, :size, :vsize, :weight, :locktime, :vin, :vout, :hex].each do |attr|
        define_method(attr) do
          raw_json.fetch(attr.to_s)
        end
      end
      alias_method :id, :txid

      def coinbase?
        vin[0].has_key?("coinbase")
      end

      def outputs
        @outputs ||= vout.map { |out| Bitcoin::Output.new(out, self) }
      end

      def amount
        outputs.sum(&:amount)
      end
    end
  end
end

# BlockchainService::Adapter.new(:bitcoin)
