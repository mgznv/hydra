module LlmProxy
  module Providers
    class OpenRouterProvider < OpenAiCompatibleProvider
      def name     = "openrouter"
      def model    = "minimax/minimax-m2.5:free"
      def base_url = "https://openrouter.ai/api/v1/chat/completions"

      private

      def api_key = ENV["OPENROUTER_API_KEY"]

      def extra_headers
        { "HTTP-Referer" => "http://localhost:4567", "X-Title" => "LLM Proxy" }
      end
    end
  end
end
