# frozen_string_literal: true

require "test_helper"

class CustomersTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get customers_path
    assert_response :success
    assert_match(/Customers/i, @response.body)
  end
end
