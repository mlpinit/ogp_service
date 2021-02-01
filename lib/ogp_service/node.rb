module OGPService
  class Node
    attr_reader :redis_client, :id, :html_reader, :parser
    def initialize(
      id:,
      html_reader: HTMLReader,
      parser: Parser,
      redis_client: Redis.new
    )
      @id = id
      @redis_client = redis_client
      @parser = parser
      @html_reader = html_reader
    end

    def set_pending_state
      redis_client.watch(id) do
        if pending_or_done?
          # The canonical id has already been set by a different Node in a
          # parallel request.
          redis_client.unwatch
        else
          # User redis watch + multi to ensure scraping only happens once
          redis_client.multi do |multi|
            # set pending state
            redis_client.set(id, pending.to_json)
            redis_client.set(initiator_key, initiator_uuid)
          end
        end
      end
    end

    def scrape
      begin
        @data = parser.new(html).data.merge(done)
      rescue => e
        puts e.inspect
        @data = error
      end
      redis_client.set(id, data.to_json)
    end

    def initiated?
      !!input_url
    end

    def pending_or_done?
      !!redis_client.get(id)
    end

    def initiator?
      redis_client.get(initiator_key) == initiator_uuid
    end

    def data
      @data || JSON.parse(redis_client.get(id))
    end

    private

    def initiator_uuid
      @initiator_uuid ||= SecureRandom.uuid
    end

    def initiator_key
      "#{id}:pending_initiator"
    end

    def pending
      shared_state.merge({ 'scrape_status' => 'pending' })
    end

    def done
      shared_state.merge({ 'scrape_status' => 'done' })
    end

    def error
      shared_state.merge({ 'scrape_status' => 'error' })
    end

    def shared_state
      { 'id' => id, 'updated_time' => current_timestamp }
    end

    def input_url
      @input_url ||= redis_client.get("#{id}:input_url")
    end

    def html
      html_reader.new(input_url).html
    end

    def current_timestamp
      Time.now.utc.iso8601
    end
  end
end
