# frozen_string_literal: true

module NlQuery
  # ENV helpers for RubyLLM Ollama provider (see config/initializers/ruby_llm.rb).
  module OllamaEnv
    DEFAULT_BASE = "http://127.0.0.1:11434"
    DEFAULT_MODEL = "qwen2.5-coder:14b"

    module_function

    # RubyLLM expects an OpenAI-compatible base URL ending in `/v1` (see rubyllm.com/configuration).
    def api_base_url
      normalize_ollama_openai_base(ENV.fetch("OLLAMA_BASE_URL", DEFAULT_BASE))
    end

    # Pure helper (unit-tested without mutating ENV).
    def normalize_ollama_openai_base(raw)
      raw = raw.to_s.strip
      raw = DEFAULT_BASE if raw.blank?
      uri = URI.parse(raw)
      unless uri.is_a?(URI::HTTP) && uri.host.present?
        raise ConfigurationError, "OLLAMA_BASE_URL must be an http(s) URL with a host (got #{raw.inspect})"
      end

      path = uri.path.to_s.chomp("/")
      uri.path = path.end_with?("/v1") ? path : "#{path}/v1"
      uri.to_s
    rescue URI::InvalidURIError
      raise ConfigurationError, "OLLAMA_BASE_URL must be a valid URL (got #{raw.inspect})"
    end

    def model_id
      m = ENV["OLLAMA_MODEL"].to_s.strip
      m = DEFAULT_MODEL if m.blank?
      m
    end
  end
end
