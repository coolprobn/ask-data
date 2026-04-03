# frozen_string_literal: true

module NlQuery
  # Thin wrapper around RubyLLM's Ollama chat — single place for network error mapping.
  class OllamaChatCompletion
    def initialize(model_id: nil)
      @model_id = model_id || OllamaEnv.model_id
    end

    def complete(system:, user:)
      chat = RubyLLM.chat(model: @model_id, provider: :ollama, assume_model_exists: true)
      chat.with_instructions(system)
      response = chat.ask(user)
      response.content.to_s
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError,
           Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT, SocketError => e
      raise LlmUnavailableError, connection_hint(e)
    rescue RubyLLM::ServiceUnavailableError, RubyLLM::ServerError => e
      raise LlmUnavailableError, "Ollama returned an error: #{e.class}: #{e.message}"
    rescue RubyLLM::Error => e
      raise LlmUnavailableError, "RubyLLM error: #{e.class}: #{e.message}"
    end

    private

    def connection_hint(cause)
      base = ENV["OLLAMA_BASE_URL"].presence || OllamaEnv::DEFAULT_BASE
      "Cannot reach Ollama at #{base} (check that Ollama is running and OLLAMA_BASE_URL is correct). " \
        "#{cause.class}: #{cause.message}"
    end
  end
end
