RSpec.describe BlockchainService::Adapter::Bitcoin do
  let(:service) { BlockchainService::Adapter.new(:btc, CONNECTION_DEFAULTS) }

  describe "connection override" do
  end

  describe "methods" do
    it "returns the current blockheight" do
      expect(service.blockheight).to be_kind_of(Integer)
    end

    describe "creating addresses" do
      it "with type=bech32 (default)" do
        expect(service.connection).to receive(:getnewaddress).with("", "bech32").and_call_original

        address = service.create_address
        expect(address.size).to eq(42)
      end

      it "with type=legacy" do
        address = service.create_address(type: "legacy")
        expect(address).to be_a(String)
        expect(address.size).to eq(34)
      end

      it "with type=p2sh-segwit" do
        address = service.create_address(type: "p2sh-segwit")
        expect(address).to be_a(String)
        expect(address.size).to eq(35)
      end

      it "with unsupported type" do
        expect {
          service.create_address(type: "type")
        }.to raise_exception ArgumentError, "unsupported address type"
      end
    end

    describe "reading a block" do
      it "returns a block hash" do
        hash = service.block_hash(1)
        expect(hash).to be_a String
        expect(hash.size).to eq(64)
      end

      it "returns block details by id" do
        block = service.block(1)
        expect(block).to be_a BlockchainService::Adapter::Bitcoin::Block
      end

      it "returns block details by hash" do
        genesis_block_hash = service.block_hash(1)
        block = service.block(genesis_block_hash)

        expect(block).to be_a BlockchainService::Adapter::Bitcoin::Block
        expect(block.id).to eq(1)
      end

      it "has one transaction in the genesis block" do
        # does such a test even make sense to test the structure of what came down?
        block = service.block(1)
        expect(block.transactions).to be_a(Array)
        expect(block.transactions.size).to eq(1)
        expect(block.transactions.first).to be_a(BlockchainService::Adapter::Bitcoin::TX)
      end
    end

    describe "a Block" do
      let(:block) { service.block(1934052) }

      it "can also be fetched by a hash" do
        block_by_hash = service.block("000000000000001ff36818f0acd9e73eac46eb66c218eed7741d0d51d0e52be3")
        expect(block.raw_json).to eq(block_by_hash.raw_json)
      end

      it "contains an array of transactions" do
        expect(block.transactions.collect(&:class).uniq).to eq([BlockchainService::Adapter::Bitcoin::TX])
      end

      it "has all the attributes that are provided from the RPC client" do
        expect(block.height).to eq(1934052)

        expect(block.previousblockhash).to be_a String
        expect(block.previousblockhash.size).to eq(64)

        expect(block.time).to be_a Integer
      end

      describe "transactions" do
        it "can return a specific transaction" do
          tx = block.transaction("8babf8802bd7720fe1099b5d4e22b8f4709419570c8e5cf34b4fffe530cda1a3")
          expect(tx).to be_a(BlockchainService::Adapter::Bitcoin::TX)
          expect(tx.amount).to eq(0.04425400)
        end

        it "returns nil if tx wasn't found in this block" do
          # it's genesis blocks coinbase TX Id, which happened in block 1
          tx = block.transaction("f0315ffc38709d70ad5647e22048358dd3745f3ce3874223c80a7c92fab0c8ba")
          expect(tx).to be_nil
        end

        describe "coinbase?" do
          it "only the first transaction is coinbase?" do
            expect(block.transactions[0]).to be_coinbase
            expect(block.transactions[1..-1].none?(&:coinbase?)).to be true
          end
        end

        it "loads the transactions just once and uses caching to access them" do
          expect(block).to receive(:transactions).once.and_call_original

          3.times do
            block.transaction("f0315ffc38709d70ad5647e22048358dd3745f3ce3874223c80a7c92fab0c8ba")
            block.transaction("7b1bea7241677b41622ed799d626247876636cc7365c7045a0707fb107d5c775")
            block.transaction("856c5e0109141a249b5a36fab3317eb35307bc5f904ff765113bcc0caed94dff")
          end
        end
      end
    end

    describe "transaction_by_hash" do
      it "returns a single transaction as a struct" do
        txid = "8babf8802bd7720fe1099b5d4e22b8f4709419570c8e5cf34b4fffe530cda1a3"
        tx = service.transaction_by_hash(txid)
        expect(tx).to be_a OpenStruct
        expect(tx.txid).to eq(txid)
      end

      it "raises an exception if we ask for a tx_id that isn't in our wallet" do
        expect {
          service.transaction_by_hash("782acaba3c8b199121f60113aa19d53146224defa8863f973d14af8de06dba3a")
        }.to raise_exception BlockchainService::Connection::ResponseError, "Invalid or non-wallet transaction id (ErrorCode: -5)"
      end
    end
  end
end
