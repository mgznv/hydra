module LlmProxy
  Response = Struct.new(:content, :model, :provider, :input_tokens, :output_tokens, keyword_init: true) do
    def to_h
      {
        content:  content,
        model:    model,
        provider: provider,
        usage: {
          input_tokens:  input_tokens,
          output_tokens: output_tokens
        }
      }
    end
  end
end
