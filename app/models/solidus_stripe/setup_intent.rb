# frozen_string_literal: true

module SolidusStripe
  class SetupIntent < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :payment_method, class_name: 'SolidusStripe::PaymentMethod'

    def self.retrieve_stripe_intent(payment_method:, order:)
      find_by(payment_method: payment_method, order: order)&.stripe_intent
    end

    def self.create_stripe_intent(payment_method:, order:, stripe_intent_options: {})
      instance = new(payment_method: payment_method, order: order)
      instance.create_stripe_intent(stripe_intent_options).tap { instance.update!(stripe_intent_id: _1.id) }
    end

    def stripe_intent
      payment_method.gateway.request do
        Stripe::SetupIntent.retrieve(stripe_intent_id)
      end
    end

    def create_stripe_intent(stripe_intent_options)
      stripe_customer_id = SolidusStripe::Customer.retrieve_or_create_stripe_customer_id(
        payment_method: payment_method,
        order: order
      )

      payment_method.gateway.request do
        Stripe::SetupIntent.create({
          customer: stripe_customer_id,
          usage: payment_method.preferred_setup_future_usage.presence,
          metadata: { solidus_order_number: order.number },
        }.merge(stripe_intent_options))
      end
    end
  end
end
