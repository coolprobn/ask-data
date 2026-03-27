# frozen_string_literal: true

require "test_helper"

module NlQuery
  class ModelReplyParserTest < ActiveSupport::TestCase
    test "parses fenced sql block" do
      text = <<~TXT
        Here is the query:
        ```sql
        SELECT 1 AS one
        ```
      TXT
      result = ModelReplyParser.parse(text)
      assert_equal "SELECT 1 AS one", result.sql
      assert_includes result.raw, "SELECT 1"
    end

    test "parses unfenced SELECT line as fallback" do
      text = "SELECT id FROM customers LIMIT 1"
      result = ModelReplyParser.parse(text)
      assert_equal "SELECT id FROM customers LIMIT 1", result.sql
    end

    test "parses WITH in fenced block" do
      text = <<~TXT
        ```sql
        WITH t AS (SELECT 1 AS x)
        SELECT * FROM t
        ```
      TXT
      result = ModelReplyParser.parse(text)
      assert_includes result.sql, "WITH"
      assert_includes result.sql, "SELECT"
    end
  end
end
