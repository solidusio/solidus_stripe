# frozen_string_literal: true

module Spree
  module Api
    class StripeController < Spree::Api::BaseController
      def create_payment_intent
        payment_method = SolidusStripe::PaymentMethod.active.last
        customer = SolidusStripe::Customer.find_or_create_by!(source: user, payment_method: payment_method)

        create_stripe_customer(customer) if customer.stripe_id.blank?

        intent = payment_method.gateway.request { Stripe::SetupIntent.create({ customer: CGI.escape(customer.stripe_id) }) }


        intent = Stripe::AddPaymentMethodIntentForUser.new.call(user: current_user)

        render json: { client_secret: intent['client_secret'] }
      end

      private

      def create_stripe_customer(customer)
        stripe_customer = customer.create_stripe_customer
        customer.update!(stripe_id: stripe_customer.id)
      end
    end
  end
end
