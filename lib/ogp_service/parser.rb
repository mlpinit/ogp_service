module OGPService
  class MissingRequiredPropertiesError < StandardError; end
  class Parser
    REQUIRED_PROPERTIES = %w[title type image url]
    ARRAY_TAGS = %w[
      og:audio
      og:image
      og:video
    ]

    def initialize(html)
      @document = Nokogiri::HTML(html)
    end

    def url
      canonical_url || og_tag_url
    end

    def data
      if missing_required_properties.any?
        raise MissingRequiredPropertiesError,
          "missing required properties: #{missing_required_properties}"
      end
      {}.tap do |struct|
        og_tags.each do |element|
          parse_tag(element, struct)
        end
      end
    end

    private

    def parse_tag(element, struct)
      property = property_value(element)
      values = property.split(':')[1..-1]
      object = values.first
      detail = values.last

      case property
      when *ARRAY_TAGS
        struct[plural(object)] ||= []
        struct[plural(object)] << {'url' => content_value(element)}
      when /^[a-zA-Z]+:[a-zA-Z]+$/ # simple tags
        struct[object] = content_value(element)
      when /og:(image|video|audio):*/ # array object detail
        struct[plural(object)].last[detail] = content_value(element)
      when 'og:locale:alternate' # locales array
        struct['alternate_locales'] ||= []
        struct['alternate_locales'] << content_value(element)
      else
        puts "Unhandled: '#{property}' value"
      end
    end

    def property_value(element)
      element&.attributes['property'].to_s
    end

    def content_value(element)
      element&.attributes['content'].to_s
    end

    def og_tags
      @document.xpath('//head/meta[starts-with(@property, \'og:\')]')
    end

    def missing_required_properties
      @missing_required_properties ||= REQUIRED_PROPERTIES.select do |property|
        !@document.xpath("boolean(//head/meta[@property='og:#{property}'])")
      end
    end

    def canonical_url
      attributes = @document.at_xpath("//head/link[@rel='canonical']")&.attributes
      attributes && attributes['href'].to_s
    end

    def og_tag_url
      attributes = @document.at_xpath("//head/meta[@property='og:url']")&.attributes
      attributes && attributes['content'].to_s
    end

    def plural(term)
      return term if term == 'music'
      "#{term}s"
    end
  end
end
