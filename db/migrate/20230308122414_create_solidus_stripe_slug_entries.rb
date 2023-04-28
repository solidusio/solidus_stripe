class CreateSolidusStripeSlugEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :solidus_stripe_slug_entries do |t|
      t.references :payment_method, null: false, foreign_key: { to_table: :spree_payment_methods }
      t.string :slug, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
