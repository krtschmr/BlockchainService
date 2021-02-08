module BlockchainService
  module Adapter
    class Bitcoin < Base
      def blockheight
        connection.getblockchaininfo.fetch("blocks")
      end

      def create_address(name = "myaddress", type: "bech32")
        raise ArgumentError, "unsupported address type" unless ["legacy", "p2sh-segwit", "bech32"].include?(type.to_s)

        connection.getnewaddress("", type)
      end

      def block_hash(id)
        connection.getblockhash(id)
      end

      def block(block_number_or_hash)
        hash = /\A\d+\Z/.match?(block_number_or_hash.to_s) ? block_hash(block_number_or_hash) : block_number_or_hash

        Block.new(connection.getblock(hash, 2)) # 2 (verbose level) = full details
      end

      def transaction_by_hash(txid, include_watchonly: false)
        json = connection.transaction_by_hash(txid, include_watchonly: include_watchonly)
        OpenStruct.new(json)
      end

      def pending_transactions
        connection.listtransactions("*", 1000, 0, true).select { |tx| tx["confirmations"] == 0 }
      end
    end
  end
end
