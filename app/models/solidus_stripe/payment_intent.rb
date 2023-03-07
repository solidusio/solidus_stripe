# frozen_string_literal: true

module SolidusStripe
  class PaymentIntent < ApplicationRecord
    belongs_to :order, class_name: 'Spree::Order'

    def stripe_payment_intent(payment_method)
      payment_method.gateway.request do
        Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
      end
    end
  end
end
