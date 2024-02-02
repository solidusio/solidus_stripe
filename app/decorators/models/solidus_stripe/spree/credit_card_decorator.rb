# frozen_string_literal: true

module SolidusStripe
  module Spree
    module CreditCard
      # Support for partial backward compatibility with solidus_stripe v5 if Payment Intents API was used in v4
      # Allows continued use of v4 credit cards saved in user's wallet_payment_sources
      # Cannot create a new v4 payment source

      def stripe_customer_id
        gateway_customer_profile_id
      end

      def stripe_payment_method_id
        gateway_payment_profile_id
      end

      def stripe_payment_method
        return if stripe_payment_method_id.blank?

        @stripe_payment_method ||= payment_method.gateway.request do
          ::Stripe::PaymentMethod.retrieve(stripe_payment_method_id)
        end
      end

      def v4?
        true
      end

      ::Spree::CreditCard.prepend self
    end
  end
end
