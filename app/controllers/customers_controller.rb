# frozen_string_literal: true

class CustomersController < ApplicationController
  def index
    @customers = Customer.order(:id)
  end
end
