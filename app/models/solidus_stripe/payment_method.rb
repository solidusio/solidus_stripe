# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string

    def partial_name
      "stripe"
    end

    def cart_partial_name
      "stripe"
    end

    def product_page_partial_name
      "stripe"
    end

    def payment_source_class
      PaymentSource
    end

    def gateway_class
      Gateway
    end

    def payment_profiles_supported?
      true
    end
  end
end
