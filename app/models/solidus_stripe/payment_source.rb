# frozen_string_literal: true

require 'stripe'

module SolidusStripe
  class PaymentSource < ::Spree::PaymentSource
    def stripe_payment_method
      return if stripe_payment_method_id.blank?

      @stripe_payment_method ||= payment_method.gateway.request { Stripe::PaymentMethod.retrieve(stripe_payment_method_id) }
    end
  end
end
