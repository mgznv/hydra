# LLM Proxy

Proxy HTTP que distribuye peticiones entre múltiples proveedores de LLM mediante round-robin, maximizando el uso de sus límites gratuitos.

## Cómo funciona

Cada petición entrante se asigna al siguiente proveedor en turno. Si tienes tres proveedores con 30 RPM cada uno, el sistema ofrece 90 RPM en total.

```
POST /chat  →  ProviderPool  →  groq (turno 1)
POST /chat  →  ProviderPool  →  openrouter (turno 2)
POST /chat  →  ProviderPool  →  anthropic (turno 3)
POST /chat  →  ProviderPool  →  groq (turno 4) ...
```

## Arquitectura

```
BaseProvider
  └── HttpProvider              # mecánica HTTP compartida
        ├── OpenAiCompatibleProvider
        │     ├── GroqProvider
        │     └── OpenRouterProvider
        └── AnthropicProvider
```

- **`Response`** — objeto de salida unificado independiente del proveedor
- **`ProviderPool`** — round-robin thread-safe con `Mutex`
- **`HttpProvider`** — `post` y `post_stream` implementados una sola vez (Template Method)

## Setup

```bash
cp .env.example .env   # completa tus API keys
bundle install
bundle exec puma -p 4567
```

## Variables de entorno

| Variable | Proveedor |
|---|---|
| `ANTHROPIC_API_KEY` | console.anthropic.com |
| `GROQ_API_KEY` | console.groq.com |
| `OPENROUTER_API_KEY` | openrouter.ai/keys |

Solo los providers con key configurada participan en la rotación.

## Endpoints

### `GET /status`
Lista los providers activos.

```bash
curl http://localhost:4567/status
# {"providers":["anthropic","groq","openrouter"]}
```

### `POST /chat`
Respuesta bloqueante. Devuelve JSON unificado.

```bash
curl -X POST http://localhost:4567/chat \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hola"}]}'
```

```json
{
  "content": "Hola, ¿en qué puedo ayudarte?",
  "model": "llama3-8b-8192",
  "provider": "groq",
  "usage": { "input_tokens": 10, "output_tokens": 12 }
}
```

### `POST /chat/stream`
Streaming via Server-Sent Events. Envía fragmentos conforme el proveedor los genera.

```bash
curl -N -X POST http://localhost:4567/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hola"}]}'
```

```
data: {"text":"Hola"}
data: {"text":", ¿en"}
data: {"text":" qué puedo"}
data: [DONE]
```

### Parámetros opcionales

| Parámetro | Tipo | Default | Descripción |
|---|---|---|---|
| `messages` | array | — | Requerido. Array de `{role, content}` |
| `system` | string | nil | Prompt de sistema |
| `max_tokens` | integer | 1024 | Máximo de tokens en la respuesta |

## Agregar un provider

Si la API es compatible con OpenAI:

```ruby
# lib/llm_proxy/providers/nuevo_provider.rb
module LlmProxy
  module Providers
    class NuevoProvider < OpenAiCompatibleProvider
      def name     = "nuevo"
      def model    = "modelo-id"
      def base_url = "https://api.nuevo.com/v1/chat/completions"

      private

      def api_key = ENV["NUEVO_API_KEY"]
    end
  end
end
```

Luego registrarlo en `lib/llm_proxy.rb`:

```ruby
require_relative "llm_proxy/providers/nuevo_provider"

def self.pool
  @pool ||= ProviderPool.new([
    ...
    Providers::NuevoProvider.new
  ])
end
```
