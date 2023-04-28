class CreateSolidusStripeSlugEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :solidus_stripe_slug_entries do |t|
      t.integer :payment_method_id, null: false, index: true
      t.string :slug, null: false, index: { unique: true }

      t.timestamps

      t.foreign_key :spree_payment_methods, column: :payment_method_id
    end
  end
end
