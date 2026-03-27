# frozen_string_literal: true

require "test_helper"

module NlQuery
  class RecordingCompletion
    attr_reader :calls

    def initialize(response_text)
      @response_text = response_text
      @calls = []
    end

    def complete(system:, user:)
      @calls << { system: system, user: user }
      @response_text
    end
  end

  class FakeCompletion
    def initialize(response_text)
      @response_text = response_text
    end

    def complete(system:, user:)
      @response_text
    end
  end

  class TextToSqlClientTest < ActiveSupport::TestCase
    test "generate uses injected completion and parses SQL" do
      fake = FakeCompletion.new(<<~R)
        ```sql
        SELECT COUNT(*) FROM orders
        ```
      R
      client = TextToSqlClient.new(completion: fake)
      result = client.generate(question: "How many orders?", schema_snapshot: "orders(id)")
      assert_equal "SELECT COUNT(*) FROM orders", result.sql
    end

    test "passes Prompts::TextToSql system prompt and schema-bound user message to completion" do
      recording = RecordingCompletion.new(<<~R)
        ```sql
        SELECT 1
        ```
      R
      client = TextToSqlClient.new(completion: recording)
      client.generate(question: "Count rows", schema_snapshot: "Table orders:\n  id (bigint)")

      assert_equal 1, recording.calls.size
      call = recording.calls.first
      assert_equal Prompts::TextToSql::SYSTEM_PROMPT, call[:system]
      assert_includes call[:user], "Table orders:"
      assert_includes call[:user], "Count rows"
      assert_includes call[:user], "Schema:"
      assert_includes call[:user], "Question:"
    end

    test "Prompts::TextToSql system prompt states SELECT-only PostgreSQL rules" do
      prompt = Prompts::TextToSql::SYSTEM_PROMPT
      assert_includes prompt, "PostgreSQL"
      assert_includes prompt, "SELECT"
      assert_includes prompt, "```sql"
    end
  end
end
