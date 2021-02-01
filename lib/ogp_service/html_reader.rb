module OGPService
  class TooManyRedirectsError < StandardError; end
  class CircularRedirectError < StandardError; end

  class HTMLReader
    def initialize(url)
      @url = url
    end

    def html
      fetch_url(@url).body
    end

    private

    def fetch_url(url, limit = 5, set = Set.new)
      raise CircularRedirectError if set.member?(url)
      raise TooManyRedirects if limit == 0
      set.add(url)

      response = Faraday.get(url)
      if redirect?(response)
        response = fetch_url(response['location'], limit - 1, set)
      end
      response
    end

    def redirect?(response)
      response.status / 100 == 3
    end
  end
end
