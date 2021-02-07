require "bigdecimal/util"

require "blockchain_service/version"
require "blockchain_service/connection_configurable"
require "blockchain_service/connection/base"
require "blockchain_service/adapter/base"
require "blockchain_service/adapter/bitcoin"
require "blockchain_service/adapter/bitcoin/block"
require "blockchain_service/adapter/bitcoin/output"
require "blockchain_service/adapter/bitcoin/tx"

require "blockchain_service/bitcoin"

module BlockchainService
  def self.new(coin, connection_override = {})
    mapping = {
      btc: "Bitcoin",
      bitcoin: "Bitcoin"
    }
    const_get(mapping[coin.to_sym]).new(connection_override)
  end
end
