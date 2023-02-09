# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_payment_method, class: 'SolidusStripe::PaymentMethod' do
    type { "SolidusStripe::PaymentMethod" }
    name { "Stripe Payment Method" }
    available_to_admin { false }
    preferences {
      {
        api_key: ENV['SOLIDUS_STRIPE_API_KEY'] || "sk_dummy_#{SecureRandom.hex(24)}",
        publishable_key: ENV['SOLIDUS_STRIPE_PUBLISHABLE_KEY'] || "pk_dummy_#{SecureRandom.hex(24)}",
      }
    }
  end

  factory :stripe_payment_source, class: 'SolidusStripe::PaymentSource' do
    association :payment_method, factory: :stripe_payment_method
  end
end
