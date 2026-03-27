# frozen_string_literal: true

require "test_helper"

module NlQuery
  class RunQueryTest < ActiveSupport::TestCase
    test "perform runs a simple select" do
      columns, rows = RunQuery.perform("SELECT 1 AS n")
      assert_includes columns, "n"
      assert_equal 1, rows.size
      assert_equal 1, rows.first["n"]
    end

    test "perform rejects non-select" do
      assert_raises(RunQuery::ExecutionError) do
        RunQuery.perform("DELETE FROM customers")
      end
    end
  end
end
