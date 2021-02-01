require './spec/spec_helper.rb'

describe OGPService::Node do
  context 'with unrecognized id' do
    it 'knows the url does not have a coresponding id' do
      node = described_class.new(id: 'fake_id')
      expect(node.initiated?).to be(false)
    end
  end

  context 'with invalid url' do
    let(:url) { 'https://twitter.com/' }
    let(:redis_client) { Redis.new }
    let(:id) { SecureRandom.uuid }
    subject { described_class.new(id: id, redis_client: redis_client) }

    before do
      redis_client.set(url, id)
      redis_client.set("#{id}:input_url", url)
    end

    it 'errors on scraping' do
      VCR.use_cassette("node_scrape_error") do
        expect do
          subject.scrape
        end.to output(/.*/).to_stdout # clears error from stdout
      end
      expect(subject.data['scrape_status']).to eq('error')
    end
  end

  context 'with valid id' do
    let(:url) { 'https://ogp.me/' }
    let(:redis_client) { Redis.new }
    let(:id) { SecureRandom.uuid }
    subject { described_class.new(id: id, redis_client: redis_client) }

    before do
      redis_client.set(url, id)
      redis_client.set("#{id}:input_url", url)
    end

    it 'knows the node has been initiated' do
      expect(subject.initiated?).to be(true)
    end

    it 'knows the node has not been scraped' do
      expect(subject.pending_or_done?).to be(false)
    end

    it 'sets status to pending before scraping' do
      subject.set_pending_state
      expect(subject.data['scrape_status']).to eq('pending')
    end

    it 'recognizes the initiator' do
      subject.set_pending_state
      expect(subject.initiator?).to be(true)
    end

    it 'scrapes data' do
      VCR.use_cassette("node_scrape_success") do
        subject.scrape
      end
      expect(subject.data['scrape_status']).to eq('done')
    end
  end

  context 'when other request already set pending state' do
    let(:url) { 'https://ogp.me/' }
    let(:redis_client) { Redis.new }
    let(:id) { SecureRandom.uuid }
    subject { described_class.new(id: id, redis_client: redis_client) }

    before do
      redis_client.set(url, id)
      redis_client.set("#{id}:input_url", url)
    end

    it 'does not update initiator id and unwatches redis key' do
      subject.set_pending_state
      initiator_id = redis_client.get("#{id}:pending_initiator")
      subject.set_pending_state
      initiator_id_two = redis_client.get("#{id}:pending_initiator")
      expect(initiator_id).to eq(initiator_id_two)
    end
  end
end
