require './spec/spec_helper.rb'

describe OGPService::Parser do
  subject { described_class.new(@html) }

  context 'without required properties' do
    it 'raises missing property error if url is missing' do
      @html = File.read("./spec/fixtures/missing_url.html")
      expect { subject.data }
        .to raise_error(
          an_instance_of(OGPService::MissingRequiredPropertiesError).
          and(having_attributes(message: 'missing required properties: ["url"]'))
      )
    end

    it 'raises missing property error if type is missing' do
      @html = File.read("./spec/fixtures/missing_type.html")
      expect { subject.data }
        .to raise_error(
          an_instance_of(OGPService::MissingRequiredPropertiesError).
          and(having_attributes(message: 'missing required properties: ["type"]'))
      )
    end

    it 'raises missing property error if image is missing' do
      @html = File.read("./spec/fixtures/missing_image.html")
      expect { subject.data }
        .to raise_error(
          an_instance_of(OGPService::MissingRequiredPropertiesError).
          and(having_attributes(message: 'missing required properties: ["image"]'))
      )
    end

    it 'raises missing property error if title is missing' do
      @html = File.read("./spec/fixtures/missing_title.html")
      expect { subject.data }
        .to raise_error(
          an_instance_of(OGPService::MissingRequiredPropertiesError).
          and(having_attributes(message: 'missing required properties: ["title"]'))
      )
    end
  end

  context 'with multiple images' do
    let(:expected_data) do
      {
        "title"=>"Open Graph protocol",
        "type"=>"website",
        "url"=>"https://ogp.me/",
        "images"=>[
          {
            "url"=>"https://ogp.me/logo.png",
            "type"=>"image/png",
            "width"=>"300",
            "height"=>"300",
            "alt"=>"The Open Graph logo"
          },
          {
            "url"=>"https://ogp.me/logo2.png",
            "type"=>"image/png2",
            "width"=>"400",
            "height"=>"400",
            "alt"=>"The Open Graph logo2"
          }
        ]
      }
    end

    before do
      @html = File.read("./spec/fixtures/multiple_images.html")
    end

    %w[url type title image].each do |kind|
      it "extracts #{kind} information" do
        expect(subject.data[kind]).to eq(expected_data[kind])
      end
    end

    %w[url type width height].each do |kind|
      it "extracts image:#{kind} information from image one" do
        expect(subject.data['images'].first[kind])
          .to eq(expected_data['images'].first[kind])
      end
    end

    %w[url type width height].each do |kind|
      it "extracts image:#{kind} information from image two" do
        expect(subject.data['images'].last[kind])
          .to eq(expected_data['images'].last[kind])
      end
    end
  end

  context 'with multiple videos' do
    let(:expected_data) do
      {
        "title"=>"Open Graph protocol",
        "type"=>"website",
        "url"=>"https://ogp.me/",
        "images"=>[
          {
            "url"=>"https://ogp.me/logo.png"
          }
        ],
        "videos"=>[
          {
            "url"=>"https://example.com/movie.swf",
            "secure_url"=>"https://secure.example.com/movie.swf",
            "type"=>"application/x-shockwave-flash",
            "width"=>"400",
            "height"=>"300"
          },
          {
            "url"=>"https://example.com/movie2.swf",
            "secure_url"=>"https://secure.example.com/movie2.swf",
            "type"=>"application/x-shockwave-flash",
            "width"=>"500",
            "height"=>"400"
          }
        ]
      }
    end

    before do
      @html = File.read("./spec/fixtures/multiple_videos.html")
    end

    %w[url type title image].each do |kind|
      it "extracts #{kind} information" do
        expect(subject.data[kind]).to eq(expected_data[kind])
      end
    end

    %w[url secure_url type width height].each do |kind|
      it "extracts video:#{kind} information from video one" do
        expect(subject.data['videos'].first[kind])
          .to eq(expected_data['videos'].first[kind])
      end
    end

    %w[url secure_url type width height].each do |kind|
      it "extracts video:#{kind} information from video two" do
        expect(subject.data['videos'].last[kind])
          .to eq(expected_data['videos'].last[kind])
      end
    end
  end

  context 'with multiple audios' do
    let(:expected_data) do
      {
        "title"=>"Open Graph protocol",
        "type"=>"website",
        "url"=>"https://ogp.me/",
        "images"=>[
          {
            "url"=>"https://ogp.me/logo.png"
          }
        ],
        "audios"=>[
          {
            "url"=>"https://example.com/sound.mp3",
            "secure_url"=>"https://secure.example.com/sound.mp3",
            "type"=>"audio/mpeg"
          },
          {
            "url"=>"https://example.com/sound2.mp3",
            "secure_url"=>"https://secure.example.com/sound2.mp3",
            "type"=>"audio/mpeg"
          }
        ]
      }
    end

    before do
      @html = File.read("./spec/fixtures/multiple_audios.html")
    end

    %w[url type title image].each do |kind|
      it "extracts #{kind} information" do
        expect(subject.data[kind]).to eq(expected_data[kind])
      end
    end

    %w[url secure_url type].each do |kind|
      it "extracts audio:#{kind} information from audio one" do
        expect(subject.data['audios'].first[kind])
          .to eq(expected_data['audios'].first[kind])
      end
    end

    %w[url secure_url type].each do |kind|
      it "extracts audio:#{kind} information from audio two" do
        expect(subject.data['audios'].last[kind])
          .to eq(expected_data['audios'].last[kind])
      end
    end
  end

  context 'with multiple locales' do
    before do
      @html = File.read("./spec/fixtures/locales.html")
    end

    it 'parses main locale' do
      expect(subject.data['locale']).to eq('en_GB')
    end

    it 'parses alternate locales' do
      expect(subject.data['alternate_locales']).to eq(['fr_FR', 'es_ES'])
    end
  end

  context 'canonical url' do
    it 'extracts url from canonical rel first' do
      @html = File.read("./spec/fixtures/with_canonical_url.html")
      expect(subject.url).to eq('https://ogp.me/?canonical')
    end

    it 'extracts url from og:url tag in rel not available' do
      @html = File.read("./spec/fixtures/missing_canonical_url.html")
      expect(subject.url).to eq('https://ogp.me/')
    end
  end

  context 'unhandled tag' do
    it 'logs unhandled tag' do
      @html = File.read("./spec/fixtures/unhandled_tag.html")
      expect { subject.data }
        .to output("Unhandled: 'og:special:tag' value\n").to_stdout
    end
  end
end
