# frozen_string_literal: true

require "test_helper"

class StaticPagesTest < ActionDispatch::IntegrationTest
  test "policy renders" do
    get policy_path
    assert_response :success
    assert_match(/What Ask Data can do/i, @response.body)
    assert_match(%r{docs/ask-data-plan\.md}, @response.body)
  end
end
