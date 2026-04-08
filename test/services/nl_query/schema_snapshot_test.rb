# frozen_string_literal: true

require "test_helper"

module NlQuery
  class SchemaSnapshotTest < ActiveSupport::TestCase
    test "for_llm includes allowlisted tables and exposed column lines" do
      text = SchemaSnapshot.for_llm
      assert_includes text, "Table customers:"
      assert_includes text, "Table orders:"
      assert_match(/email|name/i, text)
    end

    test "for_llm never lists forbidden customer columns" do
      text = SchemaSnapshot.for_llm
      assert_not_includes text.downcase, "internal_memo"
      assert_not_includes text.downcase, "api_token_digest"
    end

    test "for_llm includes primary key hints for core tables" do
      text = SchemaSnapshot.for_llm
      assert_match(/Primary key:\s+id/, text)
    end

    test "for_llm includes foreign key hints for joinable tables" do
      text = SchemaSnapshot.for_llm
      assert_includes text, "customer_id → customers.id"
      assert_includes text, "category_id → categories.id"
      assert_includes text, "order_id → orders.id"
      assert_includes text, "product_id → products.id"
    end

    test "columns_with_types omits forbidden columns from raw metadata" do
      conn = ActiveRecord::Base.connection
      cols = SchemaSnapshot.send(:columns_with_types, conn, "customers")
      names = cols.map { |h| h["name"] }
      assert_includes names, "email"
      assert_not_includes names, "internal_memo"
    end
  end
end
