module BlockchainService
  module Adapter
    class Bitcoin::Block
      attr_reader :raw_json, :id, :hash

      def initialize(raw_json)
        @raw_json = raw_json
        @hash = raw_json.dig("hash")
        @id = raw_json.dig("height")
        inspect
      end

      # :nocov:
      def inspect
        "#<#{self.class} id=#{id} hash=#{@hash}>"
      end
      # :nocov:

      [:bits, :chainwork, :confirmations, :difficulty, :hash, :height, :mediantime, :merkleroot, :nextblockhash, :nonce, :nTx, :previousblockhash, :size, :strippedsize, :time, :tx, :version, :versionHex, :weight].each do |attr|
        define_method(attr) do
          raw_json.fetch(attr.to_s)
        end
      end

      def transactions
        @tx_hash ||= {}
        @transactions ||= tx.map { |raw_tx|
          tx = Bitcoin::TX.new(raw_tx, self)
          @tx_hash[tx.id] = tx
          tx
        }
      end
      alias_method :txs, :transactions

      def transaction(hash)
        transactions unless @tx_hash # run to initialize the cache

        @tx_hash[hash]
      end
    end
  end
end
