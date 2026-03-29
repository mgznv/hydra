module LlmProxy
  module Providers
    class AnthropicProvider < HttpProvider
      def name  = "anthropic"
      def model = "claude-haiku-4-5-20251001"

      private

      def api_key = ENV["ANTHROPIC_API_KEY"]

      def api_url = "https://api.anthropic.com/v1/messages"

      def api_headers
        {
          "Content-Type"      => "application/json",
          "x-api-key"         => api_key,
          "anthropic-version" => "2023-06-01"
        }
      end

      def build_payload(messages, system, max_tokens, stream:)
        payload = { model: model, max_tokens: max_tokens, messages: messages, stream: stream }
        payload[:system] = system if system
        payload
      end

      def parse_response(data)
        Response.new(
          content:       data.dig("content", 0, "text") || "",
          model:         data["model"] || model,
          provider:      name,
          input_tokens:  data.dig("usage", "input_tokens"),
          output_tokens: data.dig("usage", "output_tokens")
        )
      end

      def extract_chunk(parsed)
        parsed.dig("delta", "text") if parsed["type"] == "content_block_delta"
      end
    end
  end
end
