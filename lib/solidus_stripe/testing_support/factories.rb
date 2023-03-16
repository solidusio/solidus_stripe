# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_payment_method, class: 'SolidusStripe::PaymentMethod' do
    type { "SolidusStripe::PaymentMethod" }
    name { "Stripe Payment Method" }
    available_to_admin { false }
    preferences {
      {
        api_key: ENV['SOLIDUS_STRIPE_API_KEY'] ||
          "sk_dummy_#{SecureRandom.hex(24)}",
        publishable_key: ENV['SOLIDUS_STRIPE_PUBLISHABLE_KEY'] ||
          "pk_dummy_#{SecureRandom.hex(24)}",
        webhook_endpoint_signing_secret: ENV['SOLIDUS_STRIPE_WEBHOOK_SIGNING_SECRET'] ||
          "whsec_dummy_#{SecureRandom.hex(32)}"
      }
    }
  end

  factory :stripe_payment_source, class: 'SolidusStripe::PaymentSource' do
    association :payment_method, factory: :stripe_payment_method
    stripe_payment_method_id { "pm_#{SecureRandom.uuid.delete('-')}" }
  end

  factory :stripe_payment_intent, class: 'SolidusStripe::PaymentIntent' do
    association :order
    association :payment_method, factory: :stripe_payment_method
    stripe_intent_id { "pm_#{SecureRandom.uuid.delete('-')}" }
  end

  factory :stripe_setup_intent, class: 'SolidusStripe::SetupIntent' do
    association :order
    association :payment_method, factory: :stripe_payment_method
    stripe_intent_id { "seti_#{SecureRandom.uuid.delete('-')}" }
  end

  factory :stripe_webhook_endpoint, class: 'SolidusStripe::WebhookEndpoint' do
    association :payment_method, factory: :stripe_payment_method
    slug { SecureRandom.hex(16) }
  end
end
