module LlmProxy
  module Providers
    class CerebrasProvider < OpenAiCompatibleProvider
      def name     = "cerebras"
      def model    = "llama3.1-8b"
      def base_url = "https://api.cerebras.ai/v1/chat/completions"

      private

      def api_key = ENV["CEREBRAS_API_KEY"]

      def build_payload(messages, system, max_tokens, stream:)
        all_messages = system ? [{ role: "system", content: system }] : []
        { model: model, messages: all_messages.concat(messages), max_completion_tokens: max_tokens, stream: stream }
      end
    end
  end
end
