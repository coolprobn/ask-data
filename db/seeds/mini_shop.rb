# frozen_string_literal: true

# Deterministic mini-shop dataset for Ask Data (see docs/ask-data-plan.md).
# Counts: 10 categories, 42 products (2 never sold), 24 customers (4 with zero orders), 75 orders.

module MiniShopSeed
  module_function

  CATEGORY_NAMES = [
    "Electronics", "Books", "Home", "Sports", "Food",
    "Toys", "Garden", "Music", "Office", "Apparel"
  ].freeze

  # 75 statuses: enough cancelled + pending for filter demos
  ORDER_STATUSES = (
    Array.new(14, "cancelled") +
    Array.new(11, "pending") +
    Array.new(25, "paid") +
    Array.new(25, "shipped")
  ).freeze

  def placed_at_for(index)
    if index < 55
      Time.utc(2024, 1, 8, 12, 0) + (index * 13).days + (index % 5).hours
    else
      j = index - 55
      Time.utc(2025, 12, 11, 10, 0) + j.days * 2 + (j % 11).hours
    end
  end

  def line_count_for(order_index)
    1 + (order_index % 5)
  end

  def run!
    raise "Expected 75 statuses" unless ORDER_STATUSES.size == 75

    categories = CATEGORY_NAMES.map { |name| Category.create!(name: name) }

    products = []
    sku_n = 0
    CATEGORY_NAMES.size.times do |ci|
      per_cat = ci < 8 ? 4 : 5 # 8×4 + 2×5 = 42 products
      per_cat.times do
        sku_n += 1
        products << Product.create!(
          name: "Seed Product #{sku_n}",
          sku: format("SEED-%03d", sku_n),
          price_cents: 1_000 + (sku_n * 173 % 40_000),
          category: categories[ci]
        )
      end
    end
    raise "Expected 42 products" unless products.size == 42

    sellable = products.first(40)
    never_sold = products.last(2)

    customers = []
    customers << Customer.create!(
      name: "Whale Wholesale LLC",
      email: "whale@seed.example.com",
      internal_memo: "VIP — expedite"
    )
    19.times do |i|
      customers << Customer.create!(
        name: "Retail Buyer #{i + 1}",
        email: format("buyer%02d@seed.example.com", i + 1),
        internal_memo: (i.even? ? nil : "Prefers email invoices")
      )
    end
    4.times do |i|
      customers << Customer.create!(
        name: "Window Shopper #{i + 1}",
        email: format("nosale%02d@seed.example.com", i + 1),
        internal_memo: "Newsletter only"
      )
    end
    raise "Expected 24 customers" unless customers.size == 24

    whale = customers.first
    buyers = customers[1, 19]

    orders = []
    75.times do |oi|
      cust =
        if oi < 38
          whale
        else
          buyers[(oi - 38) % buyers.size]
        end

      orders << Order.create!(
        customer: cust,
        status: ORDER_STATUSES[oi],
        placed_at: placed_at_for(oi),
        total_cents: 0
      )
    end

    # Line items: only sellable products; repeat product 7 on orders 2 and 60 (0-based: 3rd and 61st order)
    orders.each_with_index do |order, oi|
      n = line_count_for(oi)
      base = oi * 7
      n.times do |li|
        product =
          if oi == 2 && li == 0
            sellable[6]
          elsif oi == 59 && li == 0
            sellable[6]
          else
            sellable[(base + li) % sellable.size]
          end

        unit = product.price_cents
        unit = (unit * 1.1).to_i if order.customer == whale

        OrderItem.create!(
          order: order,
          product: product,
          quantity: 1 + ((oi + li) % 4),
          unit_price_cents: unit
        )
      end
    end

    orders.each do |order|
      total = order.order_items.sum { |i| i.quantity * i.unit_price_cents }
      order.update!(total_cents: total)
    end

    [ never_sold, categories, products, customers, orders ]
  end
end

never_sold, = MiniShopSeed.run!

Rails.logger.info { "[seeds] Mini shop: #{Category.count} categories, #{Product.count} products (#{never_sold.size} never sold), " \
                    "#{Customer.count} customers, #{Order.count} orders, #{OrderItem.count} order items." }
