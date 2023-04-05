class RenameWebhookEndpointToPaymentMethodSlugEntries < ActiveRecord::Migration[7.0]
  def change
    rename_table :solidus_stripe_webhook_endpoints, :solidus_stripe_slug_entries
  end
end
