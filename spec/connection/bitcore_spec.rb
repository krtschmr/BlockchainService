RSpec.describe BlockchainService::Connection::Bitcore do
  let(:rpc) { BlockchainService::Connection::Bitcore }
  let(:defaults) { CONNECTION_DEFAULTS.dup }
  let(:connection) { rpc.new(defaults) }

  # during development we tested against Bitcoind 0.21
  describe "configuration" do
    it "requires a user" do
      expect {
        rpc.new(defaults.merge(user: nil))
      }.to raise_exception ArgumentError, "User for RPC connection is required"
    end

    it "requires a password" do
      expect {
        rpc.new(defaults.merge(password: nil))
      }.to raise_exception ArgumentError, "Password for RPC connection is required"
    end

    it "requires a valid network" do
      expect {
        rpc.new(defaults.merge(network: :satoshi_net))
      }.to raise_exception ArgumentError, "Unknown network 'satoshi_net'"
    end

    describe "defaults" do
      it "host is localhost" do
        defaults.delete(:host)
        expect(rpc.new(defaults).host).to eq("localhost")
      end

      it "protocol is http" do
        defaults.delete(:protocol)
        expect(rpc.new(defaults).protocol).to eq("http")
      end

      it "network is testnet" do
        defaults.delete(:network)
        expect(rpc.new(defaults).network).to eq("testnet")
      end
    end
  end

  describe "authentication" do
    it "throws an unauthenticated eror with wrong user" do
      expect {
        rpc.new(defaults.merge(user: "craig wright is a fraud")).getrpcinfo
      }.to raise_exception BlockchainService::Connection::Unauthenticated
    end

    it "throws an unauthenticated eror with wrong password" do
      expect {
        rpc.new(defaults.merge(password: "craig wright is not satoshi")).getrpcinfo
      }.to raise_exception BlockchainService::Connection::Unauthenticated
    end

    it "returns a JSON(hash) if successfully authenticated" do
      call = connection.getrpcinfo
      expect(call).to have_key("active_commands")
    end
  end

  describe "error handling" do
    # starting 21.0 we receive an error that no wallet is loaded. before it was a plain method not supported
    expected_error = if ["0.18.1", "0.19.1", "0.20.1"].include?(ENV["BITCOIND_VERSION"])
      BlockchainService::Connection::MethodNotSupported
    else
      BlockchainService::Connection::NoWalletLoaded
    end

    it "returns an error if no wallet is loaded" do
      connection.unloadwallet(TEST_WALLET_NAME)
      expect {
        connection.getnewaddress("", "bech32")
      }.to raise_exception(expected_error)
    ensure
      connection.loadwallet(TEST_WALLET_NAME)
    end

    it "returns a connection error if request timeouts" do
      connection = rpc.new(defaults.merge(host: "192.137.13.37"))

      connection.instance_eval do
        def http
          Net::HTTP.new(uri.host, uri.port).tap do |http|
            http.open_timeout = 0.001
          end
        end
      end

      expect {
        connection.getrpcinfo
      }.to raise_exception BlockchainService::Connection::ConnectionError
    end

    it "returns MethodNotSupported for unknown method calls" do
      expect {
        connection.craig_wright
      }.to raise_exception BlockchainService::Connection::MethodNotSupported
    end

    it "returns ResponseError with error code if wrong arguments are provided" do
      expect {
        connection.getnewaddress("", "123")
      }.to raise_exception(BlockchainService::Connection::ResponseError).with_message("Unknown address type '123' (ErrorCode: -5)")
    end
  end

  describe "methods" do
    it "can check if an address is a valid address" do
      expect(connection.valid_address?("tbtcCraighWRightIsFraud")).to be false # faulty address, but message is correct!
      expect(connection.valid_address?("2MvpcKGSLJ2fTMHsXnZfPXUEPR19mgwMppQ")).to be true
      expect(connection.valid_address?("tb1qg6nrjvmme6yhpcu22qpkexl8pdwtwh7gteeau6")).to be true
    end
  end
end
