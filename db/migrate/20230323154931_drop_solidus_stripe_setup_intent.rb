class DropSolidusStripeSetupIntent < ActiveRecord::Migration[7.0]
  def change
    drop_table "solidus_stripe_setup_intents", force: :cascade do |t|
      t.string "stripe_intent_id"
      t.integer "order_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "payment_method_id", null: false
      t.index ["order_id"], name: "index_solidus_stripe_setup_intents_on_order_id"
      t.index ["payment_method_id"], name: "index_solidus_stripe_setup_intents_on_payment_method_id"
    end
  end
end
