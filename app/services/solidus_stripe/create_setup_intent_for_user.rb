# frozen_string_literal: true

module SolidusStripe
  class CreateSetupIntentForUser
    attr_reader :find_or_create_customer_for_user

    def initialize(find_or_create_customer_for_user: FindOrCreateCustomerForUser)
      @find_or_create_customer_for_user = find_or_create_customer_for_user
    end

    def call(user:, payment_method_id:)
      payment_method = find_stripe_payment_method(payment_method_id: payment_method_id)
      customer = find_or_create_customer_for_user.new(user: user, payment_method: payment_method).call

      intent = setup_intent(customer, payment_method)

      { client_secret: intent['client_secret'] }
    end

    private

    def find_stripe_payment_method(payment_method_id:)
      SolidusStripe::PaymentMethod.find(payment_method_id)
    end

    def setup_intent(customer, payment_method)
      payment_method.gateway.request do
        ::Stripe::SetupIntent.create({ customer: CGI.escape(customer.stripe_id) })
      end
    end
  end
end
