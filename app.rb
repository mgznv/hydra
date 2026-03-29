require "sinatra"
require "sinatra/json"
require "json"
require "dotenv/load"

# Punto de entrada temporal — se irá llenando en pasos siguientes
get "/status" do
  json({ status: "ok", message: "LLM Proxy funcionando" })
end
