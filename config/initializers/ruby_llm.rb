# frozen_string_literal: true

require "ruby_llm"
# Initializers run before Zeitwerk autoloads `app/`; load NL query env helpers explicitly.
require Rails.root.join("lib/nl_query/error.rb")
require Rails.root.join("lib/nl_query/ollama_env.rb")

RubyLLM.configure do |config|
  config.ollama_api_base = NlQuery::OllamaEnv.api_base_url
  config.default_model = NlQuery::OllamaEnv.model_id
  config.logger = Rails.logger
  config.request_timeout = ENV.fetch("RUBYLLM_REQUEST_TIMEOUT", "300").to_i
end
