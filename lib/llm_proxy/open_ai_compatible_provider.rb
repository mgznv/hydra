require "net/http"
require "json"

module LlmProxy
  class OpenAiCompatibleProvider < BaseProvider
    def base_url
      raise NotImplementedError, "#{self.class}#base_url no implementado"
    end

    def chat(messages:, system: nil, max_tokens: 1024, &block)
      payload = build_payload(messages, system, max_tokens, stream: block_given?)

      if block_given?
        post_stream(payload, &block)
      else
        data = post(payload)
        Response.new(
          content:       data.dig("choices", 0, "message", "content") || "",
          model:         data["model"] || model,
          provider:      name,
          input_tokens:  data.dig("usage", "prompt_tokens"),
          output_tokens: data.dig("usage", "completion_tokens")
        )
      end
    end

    private

    def build_payload(messages, system, max_tokens, stream:)
      all_messages = []
      all_messages << { role: "system", content: system } if system
      all_messages.concat(messages)
      { model: model, messages: all_messages, max_tokens: max_tokens, stream: stream }
    end

    def post(payload)
      uri = URI(base_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"]  = "application/json"
      req["Authorization"] = "Bearer #{api_key}"
      extra_headers.each { |k, v| req[k] = v }
      req.body = payload.to_json

      res = http.request(req)
      raise "#{name} error #{res.code}: #{res.body}" unless res.code == "200"
      JSON.parse(res.body)
    end

    def post_stream(payload, &block)
      uri = URI(base_url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"]  = "application/json"
        req["Authorization"] = "Bearer #{api_key}"
        req["Accept"]        = "text/event-stream"
        extra_headers.each { |k, v| req[k] = v }
        req.body = payload.to_json

        http.request(req) do |res|
          raise "#{name} error #{res.code}" unless res.code == "200"
          res.read_body do |chunk|
            chunk.split("\n").each do |line|
              next unless line.start_with?("data: ")
              data = line.delete_prefix("data: ").strip
              next if data == "[DONE]"
              begin
                text = JSON.parse(data).dig("choices", 0, "delta", "content")
                block.call(text) if text && !text.empty?
              rescue JSON::ParseError
                next
              end
            end
          end
        end
      end
    end

    def extra_headers
      {}
    end
  end
end
