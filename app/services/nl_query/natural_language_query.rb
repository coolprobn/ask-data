# frozen_string_literal: true

module NlQuery
  # Ticket 0.4 pipeline: ambiguity → LLM → parse → SqlGuard. No raw SQL or exceptions leak via +user_message+.
  class NaturalLanguageQuery
    def initialize(
      client: TextToSqlClient.new,
      sql_guard: SqlGuard
    )
      @client = client
      @sql_guard = sql_guard
    end

    def execute(question:, schema_snapshot:)
      support_id = SecureRandom.uuid
      q = question.to_s

      if ProductPolicy.ambiguous?(q)
        return QueryResult.new(
          outcome: :clarification_needed,
          user_message: ProductPolicy::MESSAGES[:clarification_needed],
          interpretation: nil,
          suggestions: ProductPolicy.suggestions_for(q),
          support_id: support_id,
          sql: nil,
          internal_note: "ambiguous_question"
        )
      end

      parsed = @client.generate(question: q, schema_snapshot: schema_snapshot)
      handle_parsed(parsed, support_id)
    rescue LlmUnavailableError => e
      log_exception(support_id, e)
      QueryResult.new(
        outcome: :llm_unavailable,
        user_message: ProductPolicy::MESSAGES[:llm_unavailable],
        interpretation: nil,
        suggestions: nil,
        support_id: support_id,
        sql: nil,
        internal_note: e.class.name
      )
    rescue StandardError => e
      log_exception(support_id, e)
      QueryResult.new(
        outcome: :error,
        user_message: ProductPolicy::MESSAGES[:generic_failure],
        interpretation: nil,
        suggestions: nil,
        support_id: support_id,
        sql: nil,
        internal_note: e.class.name
      )
    end

    private

    def handle_parsed(parsed, support_id)
      sql = parsed.sql.to_s.strip

      if sql.blank?
        return QueryResult.new(
          outcome: :schema_gap,
          user_message: ProductPolicy::MESSAGES[:schema_gap],
          interpretation: nil,
          suggestions: ProductPolicy.suggestions_for(""),
          support_id: support_id,
          sql: nil,
          internal_note: parsed.rationale.presence || "no_sql_in_model_reply"
        )
      end

      validation = @sql_guard.validate(sql)
      unless validation.success
        Rails.logger.info { "[NlQuery #{support_id}] SqlGuard rejected: #{validation.reason}" }
        return QueryResult.new(
          outcome: :guard_rejected,
          user_message: user_message_for_guard(validation.reason),
          interpretation: nil,
          suggestions: ProductPolicy.suggestions_for(""),
          support_id: support_id,
          sql: nil,
          internal_note: validation.reason.to_s
        )
      end

      QueryResult.new(
        outcome: :success,
        user_message: nil,
        interpretation: ProductPolicy::TRUST_COPY_SUCCESS,
        suggestions: nil,
        support_id: support_id,
        sql: sql,
        internal_note: nil
      )
    end

    def user_message_for_guard(reason)
      case reason
      when :not_select, :multi_statement, :parse_error, :disallowed_schema, :disallowed_table,
           :disallowed_column, :select_star
        ProductPolicy::MESSAGES[:guard_rejected]
      else
        ProductPolicy::MESSAGES[:bad_sql_from_model]
      end
    end

    def log_exception(support_id, error)
      Rails.logger.warn { "[NlQuery #{support_id}] #{error.class}: #{error.message}" }
    end
  end
end
