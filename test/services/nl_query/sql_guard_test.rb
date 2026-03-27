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
      assert_equal :not_select, v.reason
    end

    test "rejects UPDATE" do
      v = SqlGuard.validate("UPDATE orders SET status = 'paid' WHERE id = 1")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects DELETE" do
      v = SqlGuard.validate("DELETE FROM orders")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects DROP" do
      v = SqlGuard.validate("DROP TABLE orders")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects CREATE" do
      v = SqlGuard.validate("CREATE TABLE evil (id int)")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects COPY" do
      v = SqlGuard.validate("COPY orders FROM '/tmp/x'")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects TRUNCATE" do
      v = SqlGuard.validate("TRUNCATE orders")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects transaction control" do
      v = SqlGuard.validate("BEGIN")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects EXPLAIN SELECT" do
      v = SqlGuard.validate("EXPLAIN SELECT 1")
      assert_not v.success
      assert_equal :not_select, v.reason
    end

    test "rejects multi-statement" do
      v = SqlGuard.validate("SELECT 1; SELECT 2")
      assert_not v.success
      assert_equal :multi_statement, v.reason
    end

    test "rejects multi-statement with second statement destructive" do
      v = SqlGuard.validate("SELECT 1; DROP TABLE orders")
      assert_not v.success
      assert_equal :multi_statement, v.reason
    end

    test "rejects invalid SQL" do
      v = SqlGuard.validate("SELECT FROM")
      assert_not v.success
      assert_equal :parse_error, v.reason
    end

    test "rejects empty" do
      v = SqlGuard.validate("   ")
      assert_not v.success
      assert_equal :empty, v.reason
    end

    test "rejects comment-only input as empty" do
      v = SqlGuard.validate("-- only a comment")
      assert_not v.success
      assert_equal :empty, v.reason
    end
  end
end
