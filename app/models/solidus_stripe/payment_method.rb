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
      def find_customer_for(user)
        gateway.request do
          raise "unsupported email address: #{user.email.inspect}" if user.email.include?("'")

          Stripe::Customer.search(
            query: "metadata['solidus_user_id']:'#{user.id}' AND email:'#{user.email}'"
          ).first
        end
      end

      def create_customer_for(user)
        gateway.request do
          Stripe::Customer.create(
            email: user.email,
            metadata: { solidus_user_id: user.id },
          )
        end
      end

      def customer_for(user)
        return unless user

        find_customer_for(user) || create_customer_for(user)
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

      def customer_for_order(order)
        find_customer_for(order) || create_customer_for(order)
      end
    end

    concerning :SetupIntents do
      def find_or_create_setup_intent_for_order(order)
        find_setup_intent_for_order(order) || create_setup_intent_for_order(order)
      end

      def find_setup_intent_for_order(order)
        SolidusStripe::SetupIntent
          .find_by(order: order) # TODO: order.setup_intent (?)
          &.stripe_setup_intent(self)
      end

      def create_setup_intent_for_order(order)
        customer = customer_for(order.user) || customer_for_order(order)

        intent = gateway.request do
          Stripe::SetupIntent.create({
            customer: customer,
            usage: 'off_session', # TODO: use the payment method's preference
            metadata: { solidus_order_number: order.number },
          })
        end

        SolidusStripe::SetupIntent.create!(
          order: order,
          stripe_setup_intent_id: intent.id,
        )

        intent
      end
    end

    concerning :PaymentIntents do
      def find_or_create_payment_intent_for_order(order)
        find_payment_intent_for_order(order) || create_payment_intent_for_order(order)
      end

      def find_payment_intent_for_order(order)
        SolidusStripe::PaymentIntent
          .find_by(order: order)
          &.stripe_payment_intent(self)
      end

      def create_payment_intent_for_order(order)
        customer = customer_for(order.user) || customer_for_order(order)

        intent = gateway.request do
          Stripe::PaymentIntent.create({
            amount: gateway.to_stripe_amount(
              order.display_total.money.fractional,
              order.currency,
            ),
            currency: order.currency,

            # The capture method should stay manual in order to
            # avoid capturing the money before the order is completed.
            capture_method: 'manual',
            setup_future_usage: preferred_setup_future_usage.presence,
            customer: customer,
            metadata: { solidus_order_number: order.number },
          })
        end

        SolidusStripe::PaymentIntent.create!(
          order: order,
          stripe_payment_intent_id: intent.id,
        )

        intent
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

    def stripe_dashboard_url(payment)
      path_prefix = '/test' if preferred_test_mode

      intent_id =
        payment.transaction_id ||
        SolidusStripe::PaymentIntent.where(order: payment.order).pick(:stripe_payment_intent_id) ||
        SolidusStripe::SetupIntent.where(order: payment.order).pick(:stripe_setup_intent_id)

      case intent_id
      when /^pi_/
        "https://dashboard.stripe.com#{path_prefix}/payments/#{intent_id}"
      when /^seti_/
        "https://dashboard.stripe.com#{path_prefix}/setup_intents/#{intent_id}"
      end
    end
  end
end
