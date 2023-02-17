# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Fixtures for Stripe webhook events represented as a Ruby hash.
    #
    # Consume with `SolidusStripe::Webhook::EventWithContextFactory.from_data`.
    module DataFixtures
      def self.charge_succeeded(with_webhook: true)
        {
          "id" => "evt_3MRUo1JvEPu9yc7w091rP2XV",
          "type" => "charge.succeeded",
          "object" => "event",
          "api_version" => "2022-11-15",
          "created" => 1_674_022_050,
          "data" => {
            "object" => {
              "id" => "ch_3MRUo1JvEPu9yc7w0BglRG7L",
              "object" => "charge",
              "amount" => 2000,
              "amount_captured" => 2000,
              "amount_refunded" => 0,
              "application" => nil,
              "application_fee" => nil,
              "application_fee_amount" => nil,
              "balance_transaction" => "txn_3MRUo1JvEPu9yc7w0aaUukiY",
              "billing_details" => {
                "address" => { "city" => nil, "country" => nil, "line1" => nil, "line2" => nil, "postal_code" => nil,
                               "state" => nil },
                "email" => nil,
                "name" => nil,
                "phone" => nil
              },
              "calculated_statement_descriptor" => "NEBULAB SRL",
              "captured" => true,
              "created" => 1_674_022_049,
              "currency" => "usd",
              "customer" => nil,
              "description" => "(created by Stripe CLI)",
              "destination" => nil,
              "dispute" => nil,
              "disputed" => false,
              "failure_balance_transaction" => nil,
              "failure_code" => nil,
              "failure_message" => nil,
              "fraud_details" => {},
              "invoice" => nil,
              "livemode" => false,
              "metadata" => {},
              "on_behalf_of" => nil,
              "order" => nil,
              "outcome" => { "network_status" => "approved_by_network", "reason" => nil, "risk_level" => "normal",
                             "risk_score" => 1, "seller_message" => "Payment complete.", "type" => "authorized" },
              "paid" => true,
              "payment_intent" => "pi_3MRUo1JvEPu9yc7w0ldPcSpn",
              "payment_method" => "pm_1MRUo0JvEPu9yc7wVFMdYurf",
              "payment_method_details" => {
                "card" => { "brand" => "visa",
                            "checks" => { "address_line1_check" => nil, "address_postal_code_check" => nil,
                                          "cvc_check" => nil },
                            "country" => "US",
                            "exp_month" => 1,
                            "exp_year" => 2024,
                            "fingerprint" => "pUfqdtmzdaOnI2SE",
                            "funding" => "credit",
                            "installments" => nil,
                            "last4" => "4242",
                            "mandate" => nil,
                            "network" => "visa",
                            "three_d_secure" => nil,
                            "wallet" => nil },
                "type" => "card"
              },
              "receipt_email" => nil,
              "receipt_number" => nil,
              "receipt_url" => "https://pay.stripe.com/receipts/payment/CAcaFwoVYWNjdF8xN21MdGJKdkVQdTl5Yzd3KKKZnp4GMgahzL5hXx86LBYPolrU9mdbq37sokiWbp-wT-NGJrXXxmipTFzS_AG1Wp1Rg6HWN1F2-9ek",
              "refunded" => false,
              "refunds" => { "object" => "list", "data" => [], "has_more" => false, "total_count" => 0,
                             "url" => "/v1/charges/ch_3MRUo1JvEPu9yc7w0BglRG7L/refunds" },
              "review" => nil,
              "shipping" => {
                "address" => { "city" => "San Francisco", "country" => "US",
                               "line1" => "510 Townsend St", "line2" => nil,
                               "postal_code" => "94103", "state" => "CA" },
                "carrier" => nil, "name" => "Jenny Rosen", "phone" => nil,
                "tracking_number" => nil
              },
              "source" => nil,
              "source_transfer" => nil,
              "statement_descriptor" => nil,
              "statement_descriptor_suffix" => nil,
              "status" => "succeeded",
              "transfer_data" => nil,
              "transfer_group" => nil
            }
          },
          "livemode" => false,
          "pending_webhooks" => 3,
          "request" => "req_CAHWxuQdLQukn0"
        }.tap do |data|
          data["webhook"] = charge_succeeded(with_webhook: false) if with_webhook
        end
      end
    end
  end
end
