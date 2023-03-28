# frozen_string_literal: true

SolidusStripe.configure do |config|
  # List of webhook events you want to handle.
  # For instance, if you want to handle the `payment_intent.succeeded` event,
  # you should add it to the list below. A corresponding
  # `:"stripe.payment_intent.succeeded"` event will be published in `Spree::Bus`
  # whenever a `payment_intent.succeeded` event is received from Stripe.
  # config.webhook_events = %i[payment_intent.succeeded]
  #
  # Number of seconds while a webhook event is valid after its creation.
  # Defaults to the same value as Stripe's default.
  # config.webhook_signature_tolerance = 150
  #
  # Name of the `Spree::RefundReason` used for Stripe-generated refunds.
  # Defaults to {SolidusStripe::DEFAULT_STRIPE_REFUND_REASON_NAME}. If you
  # change it, make sure that the corresponding `Spree::RefundReason` exists in
  # the database with that name.
  # config.refund_reason_name = "Stripe refund"
end

if ENV['SOLIDUS_STRIPE_API_KEY']
  Spree::Config.static_model_preferences.add(
    'SolidusStripe::PaymentMethod',
    'solidus_stripe_env_credentials',
    api_key: ENV.fetch('SOLIDUS_STRIPE_API_KEY'),
    publishable_key: ENV.fetch('SOLIDUS_STRIPE_PUBLISHABLE_KEY'),
    test_mode: ENV.fetch('SOLIDUS_STRIPE_API_KEY').start_with?('sk_test_'),
    webhook_endpoint_signing_secret: ENV.fetch('SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET')
  )
end
