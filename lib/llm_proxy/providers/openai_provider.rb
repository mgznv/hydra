module LlmProxy
  module Providers
    class OpenAIProvider < OpenAiCompatibleProvider
      def name     = "openai"
      def model    = "gpt-4o-mini"
      def base_url = "https://api.openai.com/v1/chat/completions"

      private

      def api_key = ENV["OPENAI_API_KEY"]
    end
  end
end
