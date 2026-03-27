# frozen_string_literal: true

class CreateMiniShop < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.integer :price_cents, null: false
      t.references :category, null: false, foreign_key: true
      t.timestamps
    end
    add_index :products, :sku, unique: true

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.text :internal_memo
      t.timestamps
    end
    add_index :customers, :email, unique: true

    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :status, null: false
      t.datetime :placed_at, null: false
      t.integer :total_cents, null: false, default: 0
      t.timestamps
    end
    add_index :orders, :placed_at
    add_index :orders, :status

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.timestamps
    end
  end
end
