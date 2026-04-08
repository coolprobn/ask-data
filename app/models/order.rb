# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = %w[pending paid shipped cancelled].freeze

  belongs_to :customer
  has_many :order_items, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :placed_at, presence: true
  validates :total_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
