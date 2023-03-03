# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string
    preference :setup_future_usage, :string, default: ''
    preference :stripe_intents_flow, :string, default: 'setup'

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

    concerning :Order do
      def find_in_progress_payment_for(order)
        payments = order.payments
          .where.not(state: %w[completed invalid void]) # in_progress
          .where(payment_method: self)
          .order(:created_at)
          .entries

        *old_payments, payment = payments
        old_payments.each(&:invalidate!)

        if payment && payment.amount != order.total
          payment.cancel!
          payment = nil
        end

        payment
      end

      def create_in_progress_payment_for(order)
        transaction do
          customer = customer_for(order.user)

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
            })
          end

          order.payments
            .create!(
              payment_method: self,
              source: payment_source_class.new(payment_method: self),
              response_code: intent.id,
              amount: order.total,
            )
        end
      end

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

      def find_or_create_in_progress_payment_for(order)
        payment = find_in_progress_payment_for(order)
        intent = find_intent_for(payment) if payment

        payment = nil if intent.nil?
        payment = nil unless intent&.status == 'requires_payment_method'

        payment ||= create_in_progress_payment_for(order)
        payment
      end
    end

    concerning :Payment do
      def find_or_create_setup_intent_for_order(order)
        find_setup_intent_for_order(order) or create_setup_intent_for_order(order)
      end

      def find_setup_intent_for_order(order)
        SolidusStripe::SetupIntent
          .find_by(order: order) # TODO: order.setup_intent (?)
          &.stripe_setup_intent(self)
      end

      def create_setup_intent_for_order(order)
        customer = customer_for(order.user)

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

      def find_intent_for_order(order)
        payment = find_or_create_in_progress_payment_for(order)
        find_intent_for(payment) if payment
      end

      def find_intent_for(payment)
        return unless payment.transaction_id

        unless payment.payment_method == self
          raise ArgumentError, "this payment is from another payment_method"
        end

        raise "bad payment intent id format" unless payment.response_code.start_with?('pi_')

        gateway.request { Stripe::PaymentIntent.retrieve(payment.response_code) }
      end

      def payment_profiles_supported?
        # We actually support them, but not in the way expected by Solidus and its ActiveMerchant legacy.
        false
      end

      def stripe_dashboard_url(payment)
        # TODO: handle when the payment doesn't exist yet in Stripe, but we only have the setup intent
        intent_id = payment.transaction_id
        path_prefix = '/test' if preferred_test_mode

        "https://dashboard.stripe.com#{path_prefix}/payments/#{intent_id}"
      end
    end
  end
end
