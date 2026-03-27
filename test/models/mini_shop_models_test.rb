# frozen_string_literal: true

require "test_helper"

class MiniShopModelsTest < ActiveSupport::TestCase
  test "Order validates status" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Order.create!(
        customer: Customer.create!(name: "X", email: "x-status@y.z"),
        status: "bogus",
        placed_at: Time.current,
        total_cents: 0
      )
    end
  end

  test "associations are wired" do
    assert Category.reflect_on_association(:products)
    assert Product.reflect_on_association(:category)
    assert Customer.reflect_on_association(:orders)
    assert Order.reflect_on_association(:customer)
    assert Order.reflect_on_association(:order_items)
    assert OrderItem.reflect_on_association(:order)
    assert OrderItem.reflect_on_association(:product)
  end
end
