# frozen_string_literal: true

require "test_helper"

module NlQuery
  class ExposureTest < ActiveSupport::TestCase
    test "explicit forbidden columns are not exposed for customers" do
      assert_not Exposure.column_exposed?("customers", "internal_memo")
      assert_not Exposure.column_exposed?("customers", "api_token_digest")
    end

    test "normal customer columns are exposed when table is allowed" do
      assert Exposure.column_exposed?("customers", "name")
      assert Exposure.column_exposed?("customers", "email")
    end

    test "forbidden patterns block password and digest-style columns" do
      assert_not Exposure.column_exposed?("customers", "password")
      assert_not Exposure.column_exposed?("customers", "password_confirmation")
      assert_not Exposure.column_exposed?("customers", "bcrypt_password_digest")
    end

    test "filter_columns_for_llm omits forbidden names" do
      cols = %w[name email internal_memo api_token_digest]
      assert_equal %w[name email], Exposure.filter_columns_for_llm("customers", cols)
    end

    test "llm_schema_lines_for_table never includes forbidden column names" do
      columns = [
        { name: "name", type: "string" },
        { name: "internal_memo", type: "text" },
        { name: "email", type: "string" }
      ]
      lines = Exposure.llm_schema_lines_for_table("customers", columns)
      joined = lines.join("\n")
      assert_includes joined, "name"
      assert_includes joined, "email"
      assert_not joined.include?("internal_memo")
    end

    test "redact_result_row drops forbidden columns" do
      row = {
        "name" => "Ada",
        "email" => "ada@example.com",
        "internal_memo" => "secret note"
      }
      redacted = Exposure.redact_result_row("customers", row)
      assert_equal "Ada", redacted["name"]
      assert_equal "ada@example.com", redacted["email"]
      assert_nil redacted["internal_memo"]
    end

    test "disallowed tables expose no columns" do
      assert_not Exposure.column_exposed?("users", "id")
      assert_equal [], Exposure.filter_columns_for_llm("users", %w[id name])
    end
  end
end
