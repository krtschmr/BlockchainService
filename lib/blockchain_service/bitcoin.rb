require "blockchain_service/adapter/bitcoin"

module BlockchainService
  class Bitcoin
    include BlockchainService::ConnectionConfigurable

    class Block
      attr_accessor :transactions, :height
    end

    class Transaction
      attr_accessor :txid, :block_height, :recipient, :amount
    end

    def initialize(connection_setting = {})
      default = self.class.configuration&.connection || {}
      @connection_setting = default.merge(connection_setting)
    end

    def blockheight
      adapter.blockheight
    end

    def last_block
      get_block(blockheight)
    end

    def get_block(id)
      adapter.block(id)
    end

    def pending_transactions
      adapter.pending_transactions
    end

    # This method filters down a list of transactions (outputs) from a block
    def incoming_transactions_in_block(id, watch_addresses = [])
      return [] unless watch_addresses.any?

      parse_block(id).transactions.select { |tx| watch_addresses.include?(tx.recipient) }
    end

    # This method returns a simple Bitcoin::Block object that holds Bitcoin::Transaction
    # a transaction doesn't represent an actuall TX on the blockchain but is an actualy output
    # If a real Bitcoin Block contains a TX that sends to 100 addresses, this will actually return 100 transactions.
    # we only use outputs that are not multisignature and have an amount that's greater zero.
    def parse_block(id)
      @blocks ||= {}
      @blocks[id] ||= begin
        adapter_block = get_block(id)

        Block.new.tap do |block|
          block.height = adapter_block.id
          block.transactions = adapter_block.transactions.each_with_object([]) do |tx, array|
            tx.outputs.select { |output| output.addresses.size == 1 && output.amount.to_d > 0 }.each do |output|
              array << Transaction.new.tap do |block_tx|
                block_tx.block_height = block.height
                block_tx.recipient = output.addresses.first
                block_tx.txid = output.tx.id
                block_tx.amount = output.amount
              end
            end
          end
        end
      end
    end

    def transaction_by_hash(txid, include_watchonly: true)
      adapter.transaction_by_hash(txid, include_watchonly: true)
    end

    private

    def adapter
      @adapter ||= BlockchainService::Adapter.new(:bitcoin, @connection_setting)
    end
  end
end
