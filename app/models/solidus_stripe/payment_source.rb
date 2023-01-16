# frozen_string_literal: true

require 'stripe'

module SolidusStripe
  class PaymentSource < ::Spree::PaymentSource
    alias_attribute :gateway_payment_profile_id, :stripe_payment_intent_id
    alias_attribute :gateway_payment_profile_id=, :stripe_payment_intent_id=

    def payment_intent
      return nil if stripe_payment_intent_id.blank?

      payment_intent, _response = payment_method.gateway.client.request do
        Stripe::PaymentIntent.retrieve(stripe_payment_intent_id)
      end

      payment_intent
    end
  end
end
