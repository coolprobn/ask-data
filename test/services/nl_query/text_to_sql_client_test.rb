# frozen_string_literal: true

require "test_helper"

module NlQuery
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
  end
end
