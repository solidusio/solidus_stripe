class AddPaymentMethodReferenceToStripeIntents < ActiveRecord::Migration[7.0]
  def change
    add_reference :solidus_stripe_setup_intents, :payment_method, null: false, foreign_key: { to_table: :spree_payment_methods }
    add_reference :solidus_stripe_payment_intents, :payment_method, null: false, foreign_key: { to_table: :spree_payment_methods }
  end
end
