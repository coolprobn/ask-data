# frozen_string_literal: true

require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get orders_path
    assert_response :success
    assert_match(/Orders/i, @response.body)
  end
end
