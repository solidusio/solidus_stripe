class NormalizeStripeIntentIdAttributes < ActiveRecord::Migration[7.0]
  def change
    rename_column :solidus_stripe_payment_intents, :stripe_payment_intent_id, :stripe_intent_id
    rename_column :solidus_stripe_setup_intents, :stripe_setup_intent_id, :stripe_intent_id
  end
end
