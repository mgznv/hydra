module LlmProxy
  class BaseProvider
    def name
      raise NotImplementedError, "#{self.class}#name no implementado"
    end

    def model
      raise NotImplementedError, "#{self.class}#model no implementado"
    end

    def chat(messages:, system: nil, max_tokens: 1024)
      raise NotImplementedError, "#{self.class}#chat no implementado"
    end

    def chat_stream(messages:, system: nil, max_tokens: 1024, &block)
      raise NotImplementedError, "#{self.class}#chat_stream no implementado"
    end

    def available?
      key = api_key
      !key.nil? && !key.strip.empty?
    end

    private

    def api_key
      raise NotImplementedError, "#{self.class}#api_key no implementado"
    end
  end
end
