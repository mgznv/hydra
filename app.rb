require "sinatra"
require "sinatra/json"
require "json"
require "dotenv/load"
require_relative "lib/llm_proxy"

set :public_folder, File.join(__dir__, "public")

before do
  headers "Access-Control-Allow-Origin"  => "*",
          "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
          "Access-Control-Allow-Headers" => "Content-Type"
end

options "*" do
  200
end

get "/status" do
  json({ providers: LlmProxy.pool.available })
end

post "/chat" do
  body = JSON.parse(request.body.read)
  messages   = body["messages"]
  system     = body["system"]
  max_tokens = body["max_tokens"] || 1024

  halt 400, json({ error: "messages es requerido" }) if messages.nil? || messages.empty?

  provider = LlmProxy.pool.next_provider
  response = provider.chat(messages: messages, system: system, max_tokens: max_tokens)
  json(response.to_h)
rescue => e
  halt 503, json({ error: e.message })
end

post "/chat/stream" do
  body = JSON.parse(request.body.read)
  messages   = body["messages"]
  system     = body["system"]
  max_tokens = body["max_tokens"] || 1024

  halt 400, json({ error: "messages es requerido" }) if messages.nil? || messages.empty?

  content_type "text/event-stream"
  headers "Cache-Control" => "no-cache", "X-Accel-Buffering" => "no"

  provider = LlmProxy.pool.next_provider

  stream(:keep_open) do |out|
    provider.chat(messages: messages, system: system, max_tokens: max_tokens) do |chunk|
      out << "data: #{JSON.generate({ text: chunk })}\n\n"
    end
    out << "data: [DONE]\n\n"
  rescue => e
    out << "data: #{JSON.generate({ error: e.message })}\n\n"
  ensure
    out.close
  end
end
