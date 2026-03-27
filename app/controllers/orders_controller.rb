# frozen_string_literal: true

class OrdersController < ApplicationController
  def index
    @orders = Order.includes(:customer).order(placed_at: :desc, id: :desc)
  end
end
