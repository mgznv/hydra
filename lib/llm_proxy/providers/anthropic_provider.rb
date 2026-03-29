require "net/http"
require "json"

module LlmProxy
  module Providers
    class AnthropicProvider < BaseProvider
      API_URL = "https://api.anthropic.com/v1/messages"

      def name  = "anthropic"
      def model = "claude-haiku-4-5-20251001"

      def chat(messages:, system: nil, max_tokens: 1024, &block)
        payload = build_payload(messages, system, max_tokens, stream: block_given?)

        if block_given?
          post_stream(payload, &block)
        else
          data = post(payload)
          Response.new(
            content:       data.dig("content", 0, "text") || "",
            model:         data["model"] || model,
            provider:      name,
            input_tokens:  data.dig("usage", "input_tokens"),
            output_tokens: data.dig("usage", "output_tokens")
          )
        end
      end

      private

      def api_key = ENV["ANTHROPIC_API_KEY"]

      def build_payload(messages, system, max_tokens, stream:)
        payload = { model: model, max_tokens: max_tokens, messages: messages, stream: stream }
        payload[:system] = system if system
        payload
      end

      def headers
        {
          "Content-Type"    => "application/json",
          "x-api-key"       => api_key,
          "anthropic-version" => "2023-06-01"
        }
      end

      def post(payload)
        uri  = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri)
        headers.each { |k, v| req[k] = v }
        req.body = payload.to_json

        res = http.request(req)
        raise "anthropic error #{res.code}: #{res.body}" unless res.code == "200"
        JSON.parse(res.body)
      end

      def post_stream(payload, &block)
        uri = URI(API_URL)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          req = Net::HTTP::Post.new(uri)
          headers.each { |k, v| req[k] = v }
          req.body = payload.to_json

          http.request(req) do |res|
            raise "anthropic error #{res.code}" unless res.code == "200"
            res.read_body do |chunk|
              chunk.split("\n").each do |line|
                next unless line.start_with?("data: ")
                data = line.delete_prefix("data: ").strip
                next if data == "[DONE]"
                begin
                  parsed = JSON.parse(data)
                  if parsed["type"] == "content_block_delta"
                    text = parsed.dig("delta", "text")
                    block.call(text) if text && !text.empty?
                  end
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
end
