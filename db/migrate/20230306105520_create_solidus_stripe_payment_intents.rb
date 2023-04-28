class CreateSolidusStripePaymentIntents < ActiveRecord::Migration[7.0]
  def change
    create_table :solidus_stripe_payment_intents do |t|
      t.string :stripe_intent_id
      t.integer :order_id, null: false, index: true
      t.integer :payment_method_id, null: false, index: true

      t.timestamps

      t.foreign_key :spree_orders, column: :order_id
      t.foreign_key :spree_payment_methods, column: :payment_method_id
    end
  end
end
