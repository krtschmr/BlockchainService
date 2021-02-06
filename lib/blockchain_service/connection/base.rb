require_relative "bitcoin"
module BlockchainService
  module Connection
    class ConnectionError < StandardError; end

    class ResponseError < StandardError
      def initialize(code, msg)
        super("#{msg} (ErrorCode: #{code})")
      end
    end

    class MethodNotSupported < StandardError; end

    class Unauthenticated < StandardError; end

    class NoWalletLoaded < StandardError; end
  end
end
