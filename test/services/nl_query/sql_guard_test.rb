# frozen_string_literal: true

require "test_helper"

module NlQuery
  class SqlGuardTest < ActiveSupport::TestCase
    test "accepts simple SELECT" do
      v = SqlGuard.validate("SELECT 1")
      assert v.success
    end

    test "accepts WITH ... SELECT" do
      sql = <<~SQL
        WITH t AS (SELECT 1 AS x)
        SELECT * FROM t
      SQL
      v = SqlGuard.validate(sql)
      assert v.success
    end

    test "rejects INSERT" do
      v = SqlGuard.validate("INSERT INTO orders VALUES (1)")
      assert_not v.success
      assert_equal :forbidden_keyword, v.reason
    end

    test "rejects multi-statement" do
      v = SqlGuard.validate("SELECT 1; SELECT 2")
      assert_not v.success
      assert_equal :multi_statement, v.reason
    end

    test "rejects empty" do
      v = SqlGuard.validate("   ")
      assert_not v.success
      assert_equal :empty, v.reason
    end
  end
end
