# frozen_string_literal: true

require "test_helper"

module NlQuery
  class SchemaSnapshotTest < ActiveSupport::TestCase
    test "for_llm includes allowlisted tables and column lines" do
      text = SchemaSnapshot.for_llm
      assert_includes text, "Table customers:"
      assert_includes text, "Table orders:"
      assert_match(/email|name/i, text)
    end
  end
end
