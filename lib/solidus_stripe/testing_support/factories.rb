# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_payment_method, class: 'SolidusStripe::PaymentMethod' do
    type { "SolidusStripe::PaymentMethod" }
    name { "Stripe Payment Method" }
    preferences {
      {
        api_key: SecureRandom.hex(8),
        publishable_key: SecureRandom.hex(10),
      }
    }
  end

  factory :stripe_payment_source, class: 'SolidusStripe::PaymentSource' do
    association :payment_method, factory: :stripe_payment_method
  end
end
