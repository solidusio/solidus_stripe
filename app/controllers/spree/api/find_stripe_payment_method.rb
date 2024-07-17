# frozen_string_literal: true

module SolidusStripe
  class FindStripePaymentMethod
    def call
      SolidusStripe::PaymentMethod.active.last
    end
  end
end
