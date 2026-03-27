# frozen_string_literal: true

module NlQuery
  # User-facing copy and heuristics for Ticket 0.4 (see README + docs/ask-data-plan.md).
  module ProductPolicy
    # Suggested re-runs when a question looks underspecified (also referenced from README).
    SUGGESTED_QUESTIONS = [
      "List customers who placed an order after 10 December 2025.",
      "Total revenue in January 2025.",
      "Top 5 products by units sold.",
      "Orders that include more than one line item.",
      "Customers who have never placed an order.",
      "Average order value by month for shipped orders only."
    ].freeze

    MESSAGES = {
      clarification_needed: "That question looks a bit short on detail. Pick a clearer phrasing or try one of the examples below.",
      schema_gap: "We can’t answer that from the data exposed to Ask Data. Try rephrasing using the demo shop’s sales data, or pick one of the suggested questions.",
      guard_rejected: "We couldn’t turn that into a safe read-only query. Try simplifying the question or focusing on one table at a time.",
      bad_sql_from_model: "We couldn’t use the generated query safely. Rephrase your question, or ask about the demo shop tables only.",
      llm_unavailable: "The language model isn’t reachable right now. Check that Ollama is running and try again.",
      generic_failure: "Something went wrong while processing your question. Please try again in a moment."
    }.freeze

    TRUST_COPY_SUCCESS = "Running a single read-only SELECT against your database using only allowlisted tables and columns."

    module_function

    def ambiguous?(question)
      q = question.to_s.strip
      return true if q.blank?

      words = q.split
      return true if words.length < 3
      return true if q.length < 12

      false
    end

    # Deterministic suggestions for tests and stable demos (rotate by question hash).
    def suggestions_for(question, count: 3)
      return SUGGESTED_QUESTIONS.first(count) if question.blank?

      start = question.sum % SUGGESTED_QUESTIONS.size
      idx = (0...count).map { |i| (start + i) % SUGGESTED_QUESTIONS.size }
      idx.map { |i| SUGGESTED_QUESTIONS[i] }.uniq.first(count)
    end
  end
end
