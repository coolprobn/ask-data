# frozen_string_literal: true

require "test_helper"

module NlQuery
  class NaturalLanguageQueryTest < ActiveSupport::TestCase
    class FakeClient
      def initialize(result)
        @result = result
      end

      def generate(question:, schema_snapshot:)
        @result
      end
    end

    class RaisingClient
      def generate(**)
        raise LlmUnavailableError, "connection refused"
      end
    end

    test "stubbed INSERT yields safe user message without leaking SQL" do
      bad = TextToSqlResult.new(
        sql: "INSERT INTO customers (name) VALUES ('x')",
        rationale: nil,
        raw: "INSERT..."
      )
      nlq = NaturalLanguageQuery.new(client: FakeClient.new(bad))
      result = nlq.execute(question: "Please show me all customer names using a query", schema_snapshot: "customers(id)")

      assert_equal :guard_rejected, result.outcome
      assert_includes result.user_message.downcase, "safe"
      assert_not result.user_message.include?("INSERT")
      assert_not result.user_message.match?(/INSERT/i)
      assert_nil result.sql
    end

    test "ambiguous question returns clarification without calling LLM" do
      called = false
      client = Object.new
      client.define_singleton_method(:generate) do |**|
        called = true
        TextToSqlResult.new(sql: "SELECT 1", rationale: nil, raw: "")
      end

      nlq = NaturalLanguageQuery.new(client: client)
      result = nlq.execute(question: "no", schema_snapshot: "x")

      assert_not called
      assert_equal :clarification_needed, result.outcome
      assert result.suggestions.present?
    end

    test "no SQL in model reply maps to schema gap message" do
      empty = TextToSqlResult.new(sql: "", rationale: "Not in schema", raw: "nope")
      nlq = NaturalLanguageQuery.new(client: FakeClient.new(empty))
      result = nlq.execute(question: "What is the weather in Paris?", schema_snapshot: "orders(id)")

      assert_equal :schema_gap, result.outcome
      assert_not result.user_message.include?("orders(id)")
    end

    test "LlmUnavailable maps to safe message" do
      nlq = NaturalLanguageQuery.new(client: RaisingClient.new)
      result = nlq.execute(question: "Please list every order number for accounting", schema_snapshot: "orders(id)")

      assert_equal :llm_unavailable, result.outcome
      assert_not result.user_message.downcase.include?("refused")
      assert_not result.user_message.include?("connection")
    end

    test "user_safe_payload omits sql" do
      ok = TextToSqlResult.new(sql: "SELECT 1", rationale: nil, raw: "")
      nlq = NaturalLanguageQuery.new(client: FakeClient.new(ok))
      result = nlq.execute(question: "Count rows in orders please", schema_snapshot: "orders(id)")

      assert result.success?
      payload = result.user_safe_payload
      assert_not payload.key?(:sql)
    end
  end
end
