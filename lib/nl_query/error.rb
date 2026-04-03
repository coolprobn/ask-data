# frozen_string_literal: true

module NlQuery
  class Error < StandardError; end

  # Ollama is down, DNS failure, timeout, etc.
  class LlmUnavailableError < Error; end

  # Invalid OLLAMA_BASE_URL / other static misconfiguration
  class ConfigurationError < Error; end
end
