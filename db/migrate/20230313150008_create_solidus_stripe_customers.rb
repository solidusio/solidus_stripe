class CreateSolidusStripeCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :solidus_stripe_customers do |t|
      t.references :payment_method, null: false, foreign_key: { to_table: :spree_payment_methods }

      t.string :source_type
      t.integer :source_id

      t.string :stripe_id, index: true

      t.timestamps

      t.index [:payment_method_id, :source_type, :source_id], unique: true, name: :payment_method_and_source
    end
  end
end
