require "test_helper"

module NlQuery
  class GoldenQuestionsTest < ActiveSupport::TestCase
    def setup
      # Isolate from any prior state; no model fixtures are defined.
      OrderItem.delete_all
      Order.delete_all
      Product.delete_all
      Category.delete_all
      Customer.delete_all

      seed_small_shop
    end

    test "golden queries match expected row counts" do
      cases = [
        {
          id: :orders_after_cutoff,
          sql: "SELECT id FROM orders WHERE placed_at > '2025-01-01'",
          expected_rows: 2
        },
        { id: :customers_with_no_orders, sql: <<~SQL, expected_rows: 1 },
            SELECT c.id
            FROM customers c
            LEFT JOIN orders o ON o.customer_id = c.id
            WHERE o.id IS NULL
          SQL
        { id: :top_products_by_units, sql: <<~SQL, expected_rows: 1 },
             SELECT p.id, SUM(oi.quantity) AS units
             FROM products p
             JOIN order_items oi ON oi.product_id = p.id
             GROUP BY p.id
             HAVING SUM(oi.quantity) >= 3
           SQL
        { id: :orders_with_multiple_line_items, sql: <<~SQL, expected_rows: 2 },
            SELECT o.id
            FROM orders o
            JOIN order_items oi ON oi.order_id = o.id
            GROUP BY o.id
            HAVING COUNT(*) > 1
          SQL
        {
          id: :whale_customer_orders,
          sql: nil, # filled in at runtime from seeded whale id
          expected_rows: 2
        }
      ]

      whale_id = Customer.find_by!(email: "whale@example.test").id

      cases.each do |kase|
        sql =
          kase[:sql] || "SELECT id FROM orders WHERE customer_id = #{whale_id}"
        columns, rows = RunQuery.perform(sql)
        assert_equal kase[:expected_rows],
                     rows.size,
                     "golden #{kase[:id]} expected #{kase[:expected_rows]} rows, got #{rows.size} (columns=#{columns.inspect})"
      end
    end

    private

    def seed_small_shop
      electronics = Category.create!(name: "Electronics")
      books = Category.create!(name: "Books")

      laptop =
        Product.create!(
          name: "Laptop",
          sku: "GOLD-001",
          price_cents: 150_00,
          category: electronics
        )
      headphones =
        Product.create!(
          name: "Headphones",
          sku: "GOLD-002",
          price_cents: 50_00,
          category: electronics
        )
      novel =
        Product.create!(
          name: "Novel",
          sku: "GOLD-003",
          price_cents: 20_00,
          category: books
        )

      whale =
        Customer.create!(name: "Whale Customer", email: "whale@example.test")
      active =
        Customer.create!(name: "Active Customer", email: "active@example.test")
      window =
        Customer.create!(name: "Window Shopper", email: "window@example.test")

      # Two orders for whale after 2025-01-01, one for active before.
      o1 =
        Order.create!(
          customer: active,
          status: "paid",
          placed_at: Time.utc(2024, 12, 31, 10, 0),
          total_cents: 0
        )
      o2 =
        Order.create!(
          customer: whale,
          status: "shipped",
          placed_at: Time.utc(2025, 1, 2, 12, 0),
          total_cents: 0
        )
      o3 =
        Order.create!(
          customer: whale,
          status: "shipped",
          placed_at: Time.utc(2025, 2, 10, 9, 30),
          total_cents: 0
        )

      # Line items:
      # - o1: 1× laptop
      # - o2: 2× laptop + 1× headphones
      # - o3: 1× laptop + 1× novel
      OrderItem.create!(
        order: o1,
        product: laptop,
        quantity: 1,
        unit_price_cents: laptop.price_cents
      )

      OrderItem.create!(
        order: o2,
        product: laptop,
        quantity: 2,
        unit_price_cents: laptop.price_cents
      )
      OrderItem.create!(
        order: o2,
        product: headphones,
        quantity: 1,
        unit_price_cents: headphones.price_cents
      )

      OrderItem.create!(
        order: o3,
        product: laptop,
        quantity: 1,
        unit_price_cents: laptop.price_cents
      )
      OrderItem.create!(
        order: o3,
        product: novel,
        quantity: 1,
        unit_price_cents: novel.price_cents
      )

      [o1, o2, o3].each do |order|
        total = order.order_items.sum { |li| li.quantity * li.unit_price_cents }
        order.update!(total_cents: total)
      end
    end
  end
end
