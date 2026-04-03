# frozen_string_literal: true

module NlQuery
  module Prompts
    # NL→SQL system + user message text (Ticket 2.3 — versioned in git; no DB prompt store in v1).
    module TextToSql
      SYSTEM_PROMPT = <<~PROMPT.strip
        You translate natural language questions into a single PostgreSQL SELECT query.
        Rules:
        - Output only read-only SQL: one SELECT (WITH is allowed). No INSERT, UPDATE, DELETE, DDL, or multiple statements.
        - Use only tables and columns present in the schema snapshot in the user message. Do not invent tables or columns.
        - If the question is ambiguous or underspecified, ask a short clarifying question in plain language and omit SQL.
        - If the question cannot be answered from the schema, say so briefly and omit SQL.
        - Put the SQL in a fenced code block: ```sql ... ```
      PROMPT

      module_function

      def user_message(schema_snapshot:, question:)
        <<~MSG
          Schema:
          #{schema_snapshot}

          Question:
          #{question}
        MSG
      end
    end
  end
end
