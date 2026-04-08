# frozen_string_literal: true

require "test_helper"

module NlQuery
  class SqlRunLimitsTest < ActiveSupport::TestCase
    test "appends LIMIT when absent" do
      sql, err = SqlRunLimits.ensure_max_rows("SELECT id FROM orders", max_rows: 7)
      assert_nil err
      assert_match(/LIMIT 7\z/i, sql.strip.gsub(/\s+/, " "))
    end

    test "clamps integer LIMIT above cap" do
      sql, err = SqlRunLimits.ensure_max_rows("SELECT id FROM orders LIMIT 9999", max_rows: 50)
      assert_nil err
      assert_match(/LIMIT 50/i, sql)
    end

    test "keeps LIMIT at or below cap" do
      sql, err = SqlRunLimits.ensure_max_rows("SELECT id FROM orders LIMIT 10", max_rows: 50)
      assert_nil err
      assert_match(/LIMIT 10/i, sql)
    end

    test "replaces LIMIT ALL with cap" do
      sql, err = SqlRunLimits.ensure_max_rows("SELECT 1 LIMIT ALL", max_rows: 3)
      assert_nil err
      assert_match(/LIMIT 3/i, sql)
    end

    test "rejects non-constant LIMIT" do
      _sql, err = SqlRunLimits.ensure_max_rows("SELECT id FROM orders LIMIT (1 + 2)", max_rows: 5)
      assert_equal :dynamic_limit, err
    end
  end
end
