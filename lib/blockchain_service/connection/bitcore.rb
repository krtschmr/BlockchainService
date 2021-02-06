require "net/http"
require "uri"
require "json"

module BlockchainService
  module Connection
    class Bitcore
      attr_reader :user, :password, :host, :port, :network, :debug, :protocol

      def initialize(user:, password:, host: "localhost", port: "18332", network: "testnet", debug: true, protocol: "http")
        raise ArgumentError.new("User for RPC connection is required") unless user
        raise ArgumentError.new("Password for RPC connection is required") unless password
        raise ArgumentError.new("Unknown network '#{network}'") unless [:livenet, :testnet, :stagenet].include?(network.to_sym)

        @user = user
        @password = password
        @host = host
        @port = port
        @network = network
        @debug = debug
        @protocol = protocol
      end

      def valid_address?(address)
        request(:validateaddress, address).fetch("isvalid")
      end

      # def get_transactions(label="*", amount=100, skip=0, watchonly=false)
      #   request(:listtransactions, label, amount, skip, watchonly)
      # end

      def transaction_by_hash(txid, include_watchonly: false)
        request(:gettransaction, txid, include_watchonly)
      end

      private

      def method_missing(name, *args)
        request(name, args)
      end

      def respond_to_missing?(method_name, include_private = false)
        super
      end

      def base_uri
        "#{protocol}://#{host}:#{port}/"
      end

      def request(method, *args)
        header = {'Content-Type': "text/json"}
        params = {
          jsonrpc: 1.0,
          method: method,
          params: [args].flatten.compact
        }

        # :nocov:
        puts "sending request to #{uri}, method: #{method}, args: #{args.flatten}" if debug
        # :nocov:

        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.basic_auth(user, password)
        request.body = params.to_json
        response = http.request(request)
        raise Unauthenticated if response.code == "401" || response.code == "403"

        json = JSON.parse(response.body)

        raise MethodNotSupported if json.dig("error", "code") == -32601

        if (error = json["error"])
          case error["code"]
          when -18
            raise NoWalletLoaded
          else
            raise ResponseError.new(error["code"], error["message"])
          end
        end
        json["result"]
      rescue Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout => e
        raise ConnectionError.new(e)
      end

      def http
        Net::HTTP.new(uri.host, uri.port)
      end

      def uri
        URI.parse(base_uri)
      end
    end
  end
end
