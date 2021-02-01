module OGPService
  class IDGenerator
    attr_reader :url, :parser, :html_reader, :redis

    def initialize(
      url:,
      html_reader: HTMLReader,
      parser: Parser,
      redis: Redis
    )
      @url = url
      @html_reader = html_reader
      @parser = parser
      @redis = redis
    end

    def run
      unless canonical_id
        id = SecureRandom.uuid
        redis_client.set(canonical_url, id)
        redis_client.set("#{id}:input_url", canonical_url)
      end
      {id: canonical_id}
    end

    private

    def redis_client
      redis.new
    end

    def canonical_id
      redis_client.get(canonical_url)
    end

    def canonical_url
      # use input url if not present in og tag or canonical html tag
      @canonical_url ||=
        begin
          parser.new(html, url).url
        rescue
          url
        end
    end

    def html
      html_reader.new(url).html
    end
  end
end
