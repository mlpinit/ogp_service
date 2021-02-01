require './spec/spec_helper.rb'

describe OGPService::IDGenerator do
  context 'with invalid url' do
    subject { described_class.new(url: 'htt:\/invalid_url.com') }
    it 'returns id pointing to input_url' do
      subject = described_class.new(url: 'htt:\/invalid_url.com')
      expect(subject.run[:id].to_s.size).to eq(36)
    end

    it 'returns same id from store on a second try' do
      expect(subject.run[:id]).to eq(subject.run[:id])
    end
  end

  context 'with valid url' do
    subject { described_class.new(url: 'https://ogp.me?query') }

    it 'returns same id from store on a second try' do
      VCR.use_cassette("id_generator_success") do
        expect(subject.run[:id]).to eq(subject.run[:id])
      end
    end
  end
end
