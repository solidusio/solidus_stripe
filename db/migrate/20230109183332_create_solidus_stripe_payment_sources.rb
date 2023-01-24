class CreateSolidusStripePaymentSources < ActiveRecord::Migration[7.0]
  def change
    create_table :solidus_stripe_payment_sources do |t|
      t.integer :payment_method_id
      t.string :stripe_payment_intent_id

      t.timestamps
    end
  end
end
