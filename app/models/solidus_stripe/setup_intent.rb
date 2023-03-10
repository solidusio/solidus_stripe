# frozen_string_literal: true

module SolidusStripe
  class SetupIntent < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :payment_method, class_name: 'SolidusStripe::PaymentMethod'

    before_create :create_stripe_intent, unless: :stripe_setup_intent_id?

    def stripe_intent
      payment_method.gateway.request do
        Stripe::SetupIntent.retrieve(stripe_setup_intent_id)
      end
    end

    def create_stripe_intent
      customer = payment_method.customer_for(order)

      self.stripe_setup_intent_id = payment_method.gateway.request do
        Stripe::SetupIntent.create({
          customer: customer,
          usage: 'off_session', # TODO: use the payment method's preference
          metadata: { solidus_order_number: order.number },
        }).id
      end
    end
  end
end
