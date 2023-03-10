# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string
    preference :setup_future_usage, :string, default: ''
    preference :stripe_intents_flow, :string, default: 'setup'
    preference :skip_confirmation_for_payment_intent, :boolean, default: true

    validates :available_to_admin, inclusion: { in: [false] }
    validates :preferred_setup_future_usage, inclusion: { in: ['', 'on_session', 'off_session'] }
    validates :preferred_stripe_intents_flow, inclusion: { in: ['payment', 'setup'] }

    concerning :Configuration do
      def partial_name
        "stripe"
      end

      alias cart_partial_name partial_name
      alias product_page_partial_name partial_name
      alias risky_partial_name partial_name

      def source_required?
        true
      end

      def payment_source_class
        PaymentSource
      end

      def gateway_class
        Gateway
      end
    end

    concerning :Customer do
      def customer_for(order)
        if order.user
          find_customer_for_user(order.user) || create_customer_for_user(order.user)
        else
          find_customer_for_order(order) || create_customer_for_order(order)
        end
      end

      def find_customer_for_user(user)
        gateway.request do
          raise "unsupported email address: #{user.email.inspect}" if user.email.include?("'")

          Stripe::Customer.search(
            query: "metadata['solidus_user_id']:'#{user.id}' AND email:'#{user.email}'"
          ).first
        end
      end

      def create_customer_for_user(user)
        gateway.request do
          Stripe::Customer.create(
            email: user.email,
            metadata: { solidus_user_id: user.id },
          )
        end
      end

      def find_customer_for_order(order)
        gateway.request do
          Stripe::Customer.search(
            query: "metadata['solidus_order_number']:'#{order.number}'"
          ).first
        end
      end

      def create_customer_for_order(order)
        gateway.request do
          Stripe::Customer.create(
            email: order.email,
            metadata: { solidus_order_number: order.number },
          )
        end
      end
    end

    def skip_confirm_step?
      preferred_stripe_intents_flow == 'payment' &&
        preferred_skip_confirmation_for_payment_intent
    end

    def payment_profiles_supported?
      # We actually support them, but not in the way expected by Solidus and its ActiveMerchant legacy.
      false
    end

    # Fetches the payment intent when available, falls back on the setup intent associated to the order.
    # @api private
    # TODO: re-evaluate the need for this and think of ways to always go throught the intent classes.
    def self.intent_id_for_payment(payment)
      return unless payment

      payment.transaction_id || SolidusStripe::PaymentIntent.where(
        order: payment.order, payment_method: payment.payment_method
      )&.pick(:stripe_intent_id) || SolidusStripe::SetupIntent.where(
        order: payment.order, payment_method: payment.payment_method
      )&.pick(:stripe_intent_id)
    end

    def stripe_dashboard_url(intent_id)
      path_prefix = '/test' if preferred_test_mode

      case intent_id
      when /^pi_/
        "https://dashboard.stripe.com#{path_prefix}/payments/#{intent_id}"
      when /^seti_/
        "https://dashboard.stripe.com#{path_prefix}/setup_intents/#{intent_id}"
      end
    end
  end
end
