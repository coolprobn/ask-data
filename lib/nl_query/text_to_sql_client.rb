# frozen_string_literal: true

module NlQuery
  # Ticket 2.2: NL→SQL via RubyLLM (`OllamaChatCompletion`); prompts live in `NlQuery::Prompts::TextToSql` (Ticket 2.3).
  # Injects `completion` for tests (no Ollama required).
  class TextToSqlClient
    def initialize(completion: nil)
      @completion = completion || OllamaChatCompletion.new
    end

    def generate(question:, schema_snapshot:)
      user = Prompts::TextToSql.user_message(
        schema_snapshot: schema_snapshot.to_s,
        question: question
      )
      raw = @completion.complete(system: Prompts::TextToSql::SYSTEM_PROMPT, user: user)
      ModelReplyParser.parse(raw)
    end
  end
end
