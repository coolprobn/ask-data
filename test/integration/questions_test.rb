# frozen_string_literal: true

require "test_helper"

class QuestionsTest < ActionDispatch::IntegrationTest
  test "ask renders at root" do
    get root_path
    assert_response :success
    assert_match(/Ask Data/i, @response.body)
  end

  test "ask renders at /ask" do
    get ask_path
    assert_response :success
    assert_match(/Ask Data/i, @response.body)
  end
end
