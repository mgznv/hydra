module LlmProxy
  class OpenAiCompatibleProvider < HttpProvider
    def base_url = raise NotImplementedError, "#{self.class}#base_url no implementado"

    private

    def api_url = base_url

    def api_headers
      { "Content-Type" => "application/json", "Authorization" => "Bearer #{api_key}" }
        .merge(extra_headers)
    end

    def build_payload(messages, system, max_tokens, stream:)
      all_messages = system ? [{ role: "system", content: system }] : []
      { model: model, messages: all_messages.concat(messages), max_tokens: max_tokens, stream: stream }
    end

    def parse_response(data)
      Response.new(
        content:       data.dig("choices", 0, "message", "content") || "",
        model:         data["model"] || model,
        provider:      name,
        input_tokens:  data.dig("usage", "prompt_tokens"),
        output_tokens: data.dig("usage", "completion_tokens")
      )
    end

    def extract_chunk(parsed)
      parsed.dig("choices", 0, "delta", "content")
    end

    def extra_headers = {}
  end
end
