require "bundler/setup"
require "simplecov"
require "codecov"
require "pry"
require "assert_difference"

SimpleCov.start do
  enable_coverage :branch
end

if ENV["COVERAGE"]
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require "blockchain_service"

CONNECTION_DEFAULTS = {
  user: "test",
  password: "test",
  host: "192.168.0.21",
  port: 18332,
  debug: false,
  network: :testnet
}

TEST_WALLET_NAME = "test"

RSpec.configure do |config|
  config.include AssertDifference

  # # Enable flags like --only-failures and --next-failure
  # config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.before(:suite) do
    # make sure there's a wallet loaded
    connection = BlockchainService::Connection::Bitcoin.new(CONNECTION_DEFAULTS)
    begin
      # but first close all current ones.
      connection.listwallets.each { |wallet| connection.unloadwallet(wallet) }
    rescue
      # shall never happen
    end

    connection.loadwallet(TEST_WALLET_NAME)
  rescue => e
    # if the wallet is already loaded, it throws an exception, which is a good thing in this case
    unless e.message.include?("is already loaded. (ErrorCode: -4)")
      # if we can't open the test-wallet, we need to abort the whole spec
      raise "can't load wallet '#{TEST_WALLET_NAME}' on RPC. Suite aborted."
    end
  end
end
