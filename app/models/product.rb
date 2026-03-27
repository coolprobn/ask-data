# frozen_string_literal: true

class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :restrict_with_exception

  validates :name, :sku, :price_cents, presence: true
  validates :sku, uniqueness: true
  validates :price_cents, numericality: { only_integer: true, greater_than: 0 }
end
