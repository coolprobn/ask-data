module ApplicationHelper
  def nav_link_classes(active)
    if active
      "font-semibold text-gray-900"
    else
      "text-gray-600 hover:text-gray-900"
    end
  end

  def nav_active?(key)
    case key
    when :ask
      controller_name == "questions"
    when :customers
      controller_name == "customers"
    when :products
      controller_name == "products"
    when :orders
      controller_name == "orders"
    when :policy
      controller_name == "static_pages" && action_name == "policy"
    else
      false
    end
  end
end
