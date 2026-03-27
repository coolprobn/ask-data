# frozen_string_literal: true

module NlQuery
  # Builds NL→SQL prompts and parses the model reply. Injects `completion` for tests (no Ollama required).
  class TextToSqlClient
    SYSTEM_PROMPT = <<~PROMPT.strip
      You translate natural language questions into a single PostgreSQL SELECT query.
      Rules:
      - Output only read-only SQL: one SELECT (WITH is allowed). No INSERT, UPDATE, DELETE, DDL, or multiple statements.
      - Use only tables and columns present in the schema snapshot in the user message.
      - Put the SQL in a fenced code block: ```sql ... ```
      - If the question cannot be answered from the schema, explain briefly and omit SQL.
    PROMPT

    def initialize(completion: nil)
      @completion = completion || OllamaChatCompletion.new
    end

    def generate(question:, schema_snapshot:)
      user = build_user_message(question: question, schema_snapshot: schema_snapshot.to_s)
      raw = @completion.complete(system: SYSTEM_PROMPT, user: user)
      ModelReplyParser.parse(raw)
    end

    private

    def build_user_message(question:, schema_snapshot:)
      <<~MSG
        Schema:
        #{schema_snapshot}

        Question:
        #{question}
      MSG
    end
  end
end
