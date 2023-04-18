# frozen_string_literal: true

FactoryBot.define do
  factory :solidus_stripe_payment_method, class: 'SolidusStripe::PaymentMethod' do
    type { "SolidusStripe::PaymentMethod" }
    name { "Stripe Payment Method" }
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

  factory :solidus_stripe_payment_source, class: 'SolidusStripe::PaymentSource' do
    association :payment_method, factory: :solidus_stripe_payment_method
    stripe_payment_method_id { "pm_#{SecureRandom.uuid.delete('-')}" }
  end

  factory :solidus_stripe_payment, parent: :payment do
    association :payment_method, factory: :solidus_stripe_payment_method
    amount { order.outstanding_balance }
    response_code { "pi_#{SecureRandom.uuid.delete('-')}" }
    state { 'checkout' }

    transient do
      stripe_payment_method_id { "pm_#{SecureRandom.uuid.delete('-')}" }
    end

    source {
      create(
        :solidus_stripe_payment_source,
        payment_method: payment_method,
        stripe_payment_method_id: stripe_payment_method_id
      )
    }

    trait :authorized do
      state { 'pending' }

      after(:create) do |payment, _evaluator|
        create(
          :solidus_stripe_payment_log_entry,
          :authorize,
          source: payment
        )
      end
    end

    trait :captured do
      state { 'completed' }

      after(:create) do |payment, _evaluator|
        create(
          :solidus_stripe_payment_log_entry,
          :autocapture,
          source: payment
        )
      end
    end
  end

  factory :solidus_stripe_payment_intent, class: 'SolidusStripe::PaymentIntent' do
    association :order
    association :payment_method, factory: :solidus_stripe_payment_method
    stripe_intent_id { "pm_#{SecureRandom.uuid.delete('-')}" }
  end

  factory :solidus_stripe_slug_entry, class: 'SolidusStripe::SlugEntry' do
    association :payment_method, factory: :solidus_stripe_payment_method
    slug { SecureRandom.hex(16) }
  end

  factory :solidus_stripe_customer, class: 'SolidusStripe::Customer' do
    association :payment_method, factory: :solidus_stripe_payment_method
    association :source, factory: :user
    stripe_id { "cus_#{SecureRandom.uuid.delete('-')}" }

    trait :guest do
      association :source, factory: :order, email: 'guest@example.com', user: nil
    end
  end

  factory :solidus_stripe_payment_log_entry, class: 'Spree::LogEntry' do
    transient do
      success { true }
      message { nil }
      response_code { source.response_code }
      data { nil }
    end

    source { create(:payment) }

    trait :authorize do
      message { 'PaymentIntent was confirmed successfully' }
    end

    trait :capture do
      message { 'Payment captured successfully' }
    end

    trait :autocapture do
      message { 'PaymentIntent was confirmed and captured successfully' }
    end

    trait :void do
      message { 'PaymentIntent was canceled successfully' }
    end

    trait :refund do
      message { 'PaymentIntent was refunded successfully' }
    end

    trait :fail do
      success { false }
      message { 'PaymentIntent operation failed with a generic error' }
    end

    details {
      YAML.safe_dump(
        SolidusStripe::LogEntries.build_payment_log(
          success: success,
          message: message,
          response_code: response_code,
          data: data
        ),
        permitted_classes: Spree::LogEntry.permitted_classes,
        aliases: Spree::Config.log_entry_allow_aliases
      )
    }
  end

  factory :order_with_stripe_payment, parent: :order do
    transient do
      amount { 10 }
      payment_method { build(:solidus_stripe_payment_method) }
      stripe_payment_method_id { "pm_#{SecureRandom.uuid.delete('-')}" }
    end

    line_items { [build(:line_item, price: amount)] }

    after(:create) do |order, evaluator|
      build(
        :solidus_stripe_payment,
        amount: evaluator.amount,
        order: order,
        payment_method: evaluator.payment_method,
        stripe_payment_method_id: evaluator.stripe_payment_method_id
      )
      order.recalculate
    end
  end
end
