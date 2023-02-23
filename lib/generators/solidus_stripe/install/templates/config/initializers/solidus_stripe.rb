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
end

# Allow sending the payment id in the payment form and avoid the automatic
# creation of an additional payment by Spree::PaymentCreate.
#
# We're providing a inline module to make it easier to remove the mokey-patch
# once the upstream PR is merged and generally available.
#
# Fixes https://github.com/solidusio/solidus/issues/2680
# Fixed by https://github.com/solidusio/solidus/pull/4909
begin
  module SolidusStripe::PaymentCreateWithExistingPayment
    def build
      # https://stackoverflow.com/a/62397649
      if attributes[:stripe_intent_id]
        @payment = order.payments.find_by!(response_code: attributes[:stripe_intent_id])
      else
        super
      end
    end
  end

  Rails.application.reloader.to_prepare do
    Spree::PaymentCreate.prepend SolidusStripe::PaymentCreateWithExistingPayment
  end

  Spree::PermittedAttributes.checkout_payment_attributes.first[:payments_attributes] << :stripe_intent_id
end

if ENV['SOLIDUS_STRIPE_API_KEY']
  Rails.application.reloader.to_prepare do
    Spree::Config.static_model_preferences.add(
      SolidusStripe::PaymentMethod,
      'solidus_stripe_env_credentials',
      api_key: ENV.fetch('SOLIDUS_STRIPE_API_KEY'),
      publishable_key: ENV.fetch('SOLIDUS_STRIPE_PUBLISHABLE_KEY'),
      test_mode: ENV.fetch('SOLIDUS_STRIPE_API_KEY').start_with?('sk_test_'),
    )
  end
end
