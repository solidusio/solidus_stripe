# frozen_string_literal: true

require 'stripe'

module SolidusStripe
  class PaymentSource < ::Spree::PaymentSource
    def stripe_payment_method
      return if stripe_payment_method_id.blank?

      @stripe_payment_method ||= payment_method.gateway.request do
        Stripe::PaymentMethod.retrieve(stripe_payment_method_id)
      end
    end

    def actions
      %w[capture void credit]
    end

    def can_capture?(payment)
      payment.pending?
    end

    def can_void?(payment)
      payment.pending?
    end

    def can_credit?(payment)
      payment.completed? && payment.credit_allowed > 0
    end

    def v4?
      false
    end
  end
end
