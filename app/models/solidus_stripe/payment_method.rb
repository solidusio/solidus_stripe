# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string

    def partial_name
      "stripe"
    end

    alias cart_partial_name partial_name
    alias product_page_partial_name partial_name

    def payment_source_class
      PaymentSource
    end

    def gateway_class
      Gateway
    end

    def create_profile(payment)
      payment_intent = payment.source.payment_intent

      if payment_intent && payment_intent.customer.blank?
        payment.payment_method.gateway.request do
          payment_intent.customer = Stripe::Customer.new email: payment.order.email
          payment_intent.customer.save
          payment_intent.save
        end
      end

      self
    end

    def payment_profiles_supported?
      true
    end
  end
end
