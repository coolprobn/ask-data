# frozen_string_literal: true

require "test_helper"

module NlQuery
  class OllamaEnvTest < ActiveSupport::TestCase
    test "normalize_ollama_openai_base appends /v1 when missing" do
      assert_equal "http://127.0.0.1:11434/v1",
                   OllamaEnv.normalize_ollama_openai_base("http://127.0.0.1:11434")
    end

    test "normalize_ollama_openai_base preserves existing /v1" do
      assert_equal "http://127.0.0.1:11434/v1",
                   OllamaEnv.normalize_ollama_openai_base("http://127.0.0.1:11434/v1")
    end

    test "normalize_ollama_openai_base raises ConfigurationError on invalid URL" do
      assert_raises(NlQuery::ConfigurationError) do
        OllamaEnv.normalize_ollama_openai_base("not a url")
      end
    end
  end
end
