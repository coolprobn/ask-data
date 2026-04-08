# frozen_string_literal: true

require "test_helper"

class ProductsTest < ActionDispatch::IntegrationTest
  test "index renders" do
    get products_path
    assert_response :success
    assert_match(/Products/i, @response.body)
  end
end
