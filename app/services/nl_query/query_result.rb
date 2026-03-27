# frozen_string_literal: true

module NlQuery
  # What callers may show users: never put raw SQL or stack traces in +user_message+ on error paths.
  QueryResult = Data.define(
    :outcome,
    :user_message,
    :interpretation,
    :suggestions,
    :support_id,
    :sql,
    :internal_note
  ) do
    def success?
      outcome == :success
    end

    # SQL is only for internal execution/logging; UI should not render it to end users until Epic 4 hardens UX.
    def user_safe_payload
      {
        outcome: outcome,
        message: user_message,
        interpretation: interpretation,
        suggestions: suggestions,
        support_id: support_id
      }.compact
    end
  end
end
