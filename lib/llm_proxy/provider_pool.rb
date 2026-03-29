module LlmProxy
  class ProviderPool
    def initialize(providers)
      @providers = providers.select(&:available?)
      raise ArgumentError, "No hay providers disponibles. Revisa tus API keys en .env" if @providers.empty?
      @current = 0
      @mutex   = Mutex.new
    end

    def next_provider
      @mutex.synchronize do
        provider = @providers[@current % @providers.size]
        @current += 1
        provider
      end
    end

    def available
      @providers.map(&:name)
    end
  end
end
