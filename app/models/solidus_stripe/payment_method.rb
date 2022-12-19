# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string

    def payment_source_class
      PaymentSource
    end

    def gateway_class
      Gateway
    end
  end
end
