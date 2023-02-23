# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string

    validates :available_to_admin, inclusion: { in: [false] }

    concerning :Configuration do
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
    end

    concerning :Payment do
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

      def stripe_dashboard_url(payment)
        intent_id = payment.source.stripe_payment_intent_id
        path_prefix = '/test' if preferred_test_mode

        "https://dashboard.stripe.com#{path_prefix}/payments/#{intent_id}"
      end
    end
  end
end
