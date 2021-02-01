require './spec/spec_helper.rb'

describe OGPService::HTMLReader do
  subject { described_class.new(url) }

  context 'with circular redirect' do
    let(:url) { "http://www.google.com" }

    it 'raises an error' do
      # Note: Fixture has been manually updated to mimic a 301
      VCR.use_cassette("circular_redirect") do
        expect { subject.html }
          .to raise_error(OGPService::CircularRedirectError)
      end
    end
  end

  context 'when request is valid' do
    let(:url) { "http://ogp.me/" }

    it 'reads html body' do
      VCR.use_cassette("success") do
        html =  subject.html
        expect(html).to match(/html/)
        expect(html).to match(/meta/)
        expect(html).to match(/link/)
      end
    end
  end
end
