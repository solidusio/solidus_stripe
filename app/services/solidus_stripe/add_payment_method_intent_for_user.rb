# frozen_string_literal: true

module SolidusStripe
  class AddPaymentMethodIntentForUser
    def initialize(find_or_create_customer_for_user: FindOrCreateCustomerForUser.new,
                   find_stripe_payment_method: FindStripePaymentMethod.new)
      @find_or_create_customer_for_user = find_or_create_customer_for_user
      @find_stripe_payment_method = find_stripe_payment_method
    end

    def call(user:)
      payment_method = @find_stripe_payment_method.call
      customer = @find_or_create_customer_for_user.call(user: user)
      payment_method.gateway.request { ::Stripe::SetupIntent.create({ customer: CGI.escape(customer.stripe_id) }) }
    end
  end
end
