module BlockchainService
  module Adapter
    def self.new(coin, connection_override = {})
      mapping = {
        btc: "Bitcoin",
        bitcoin: "Bitcoin"
      }
      const_get(mapping[coin.to_sym]).new(connection_override)
    end

    class Base
      def initialize(connection_override = {})
        @connection_override = connection_override
      end

      def connection
        target = "BlockchainService::Connection::#{self.class.to_s.split("::").last}"
        @connection ||= Object.const_get(target).new(@connection_override)
      end
    end
  end
end
