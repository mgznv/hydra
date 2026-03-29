require_relative "llm_proxy/response"
require_relative "llm_proxy/base_provider"
require_relative "llm_proxy/http_provider"
require_relative "llm_proxy/open_ai_compatible_provider"
require_relative "llm_proxy/providers/anthropic_provider"
require_relative "llm_proxy/providers/groq_provider"
require_relative "llm_proxy/providers/openrouter_provider"
require_relative "llm_proxy/provider_pool"

module LlmProxy
  def self.pool
    @pool ||= ProviderPool.new([
      Providers::AnthropicProvider.new,
      Providers::GroqProvider.new,
      Providers::OpenRouterProvider.new
    ])
  end
end
