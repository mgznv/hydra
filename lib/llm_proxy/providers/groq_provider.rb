module LlmProxy
  module Providers
    class GroqProvider < OpenAiCompatibleProvider
      def name     = "groq"
      def model    = "llama3-8b-8192"
      def base_url = "https://api.groq.com/openai/v1/chat/completions"

      private

      def api_key = ENV["GROQ_API_KEY"]
    end
  end
end
