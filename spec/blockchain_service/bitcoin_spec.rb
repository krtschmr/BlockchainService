RSpec.describe BlockchainService::Bitcoin do
  let(:service) { BlockchainService.new(:bitcoin, CONNECTION_DEFAULTS) }

  it "returns blockheight" do
    expect(service.blockheight).to be_a Integer
  end

  it "returns the last block" do
    expect(service.last_block).to be_a BlockchainService::Adapter::Bitcoin::Block
  end

  describe "scanning for incoming transactions" do
    it "returns an empty array if we don't provide observed addresses" do
      expect(service.incoming_transactions_in_block(1934370, [])).to eq([])
    end

    it "returns inputs that came to our addresses, wrapped into one signle transaction with 7 outputs" do
      # This transaction (c7b9af659609166a70b152012b5b6a7cbed8638eb58559579974c1e849eb66c1)
      # was mined in block 1934370 on testnet3
      # it contained 7 outputs for us and one who didn't belong to us
      # tb1ql996agt563f668fajmxhdwc439n9h5tq7dlpsp	     0.0011
      # tb1qwexn3vua5tg26klgm0r55evk8880caksf0y0vn	     0.0021
      # tb1qxl0fpjt0e7meq5ljvtu4uzrpcl3xhhsv80uyvj	     0.0031
      # tb1qx4m8822s4sxntx92q9mpznmw48yjyya8h0vt2x	     0.0041
      # tb1qlvj89hd5wsjcpj7s6mtd7dgesp4crv8vuj4jwe	     0.0051
      # tb1qdaucgy8hprkwvh6kszusyy29ysljhrmdmch03m	     0.0061
      # tb1q7yw3pq6dhd3qyp8tvqzht2llud0rkslwv672hy	     0.0071
      # tb1qw70tm34fpk9vudsuceake0n4vtl3cz37nhkg3n	     0.014503 (return address)

      # a similar one to play with was mined in block 1934056

      # this is a hash of addresses that we expect and amounts
      our_addresses = {
        "tb1CraigWRightIsNotSatoshiHeIsAFraudScamstar" => 0,
        "tb1q22823ykuq2eme2eq72ncyncej24qnzgw2hus6m" => 0,
        "tb1q7yw3pq6dhd3qyp8tvqzht2llud0rkslwv672hy" => 0.0071,
        "tb1q8rg7cf7fwxmyxxghwh0408tpefpsr7k4xehnmw" => 0,
        "tb1qdaucgy8hprkwvh6kszusyy29ysljhrmdmch03m" => 0.0061,
        "tb1qf3tgc7k94mh3lczrl30rnw4h82nc9cqf3r38q4" => 0,
        "tb1ql996agt563f668fajmxhdwc439n9h5tq7dlpsp" => 0.0011,
        "tb1qlvj89hd5wsjcpj7s6mtd7dgesp4crv8vuj4jwe" => 0.0051,
        "tb1qwexn3vua5tg26klgm0r55evk8880caksf0y0vn" => 0.0021,
        "tb1qx4m8822s4sxntx92q9mpznmw48yjyya8h0vt2x" => 0.0041,
        "tb1qxl0fpjt0e7meq5ljvtu4uzrpcl3xhhsv80uyvj" => 0.0031,
        "tb1qzu3l9zsfk4fly8zmldckl7cz4ln86r4pc0cqt4" => 0
      }

      txs_in_block = service.incoming_transactions_in_block(1934370, our_addresses.keys)
      expect(txs_in_block.size).to eq(7)
      our_addresses.each do |address, expected_amount|
        if expected_amount == 0
          expect(txs_in_block.detect { |tx| tx.recipient == address }).to be nil
        else
          expect(txs_in_block.detect { |tx| tx.recipient == address }.amount).to eq(expected_amount)
        end
      end
    end
  end
end
