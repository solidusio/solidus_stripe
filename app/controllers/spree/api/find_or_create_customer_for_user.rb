# frozen_string_literal: true

module SolidusStripe
  class FindOrCreateCustomerForUser
    def initialize(find_stripe_payment_method: FindStripePaymentMethod.new)
      @find_stripe_payment_method = find_stripe_payment_method
    end

    def call(user:)
      payment_method = @find_stripe_payment_method.call

      customer = SolidusStripe::Customer.find_or_create_by!(source: user, payment_method: payment_method)
      return customer if customer.stripe_id.present?

      stripe_customer = customer.create_stripe_customer
      customer.update!(stripe_id: stripe_customer.id)
      customer
    end
  end
end
