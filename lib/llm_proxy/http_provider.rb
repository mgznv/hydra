require "net/http"
require "json"

module LlmProxy
  class HttpProvider < BaseProvider
    def chat(messages:, system: nil, max_tokens: 1024, &block)
      payload = build_payload(messages, system, max_tokens, stream: block_given?)
      block_given? ? post_stream(payload, &block) : parse_response(post(payload))
    end

    private

    def api_url    = raise NotImplementedError, "#{self.class}#api_url no implementado"
    def api_headers = raise NotImplementedError, "#{self.class}#api_headers no implementado"

    def build_payload(messages, system, max_tokens, stream:)
      raise NotImplementedError, "#{self.class}#build_payload no implementado"
    end

    def parse_response(data)
      raise NotImplementedError, "#{self.class}#parse_response no implementado"
    end

    def extract_chunk(parsed)
      raise NotImplementedError, "#{self.class}#extract_chunk no implementado"
    end

    def post(payload)
      uri = URI(api_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      req = Net::HTTP::Post.new(uri)
      api_headers.each { |k, v| req[k] = v }
      req.body = payload.to_json

      res = http.request(req)
      raise "#{name} error #{res.code}: #{res.body}" unless res.code == "200"
      JSON.parse(res.body)
    end

    def post_stream(payload, &block)
      uri = URI(api_url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        req = Net::HTTP::Post.new(uri)
        api_headers.merge("Accept" => "text/event-stream").each { |k, v| req[k] = v }
        req.body = payload.to_json

        http.request(req) do |res|
          raise "#{name} error #{res.code}" unless res.code == "200"
          res.read_body do |chunk|
            chunk.split("\n").each do |line|
              next unless line.start_with?("data: ")
              data = line.delete_prefix("data: ").strip
              next if data == "[DONE]"
              begin
                text = extract_chunk(JSON.parse(data))
                block.call(text) if text && !text.empty?
              rescue JSON::ParseError
                next
              end
            end
          end
        end
      end
    end
  end
end
