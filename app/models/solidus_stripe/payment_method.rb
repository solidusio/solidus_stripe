# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string
    preference :setup_future_usage, :string, default: ''
    preference :stripe_intents_flow, :string, default: 'setup'
    preference :skip_confirmation_for_payment_intent, :boolean, default: true

    # @attribute [rw] preferred_webhook_endpoint_signing_secret The webhook endpoint signing secret
    #  for this payment method.
    # @see https://stripe.com/docs/webhooks/signatures
    preference :webhook_endpoint_signing_secret, :string

    validates :available_to_admin, inclusion: { in: [false] }
    validates :preferred_setup_future_usage, inclusion: { in: ['', 'on_session', 'off_session'] }
    validates :preferred_stripe_intents_flow, inclusion: { in: ['payment', 'setup'] }

    has_one :webhook_endpoint,
      class_name: 'SolidusStripe::WebhookEndpoint',
      inverse_of: :payment_method,
      dependent: :destroy

    after_create :assign_webhook_endpoint

    # @!attribute [r] webhook_endpoint_slug
    #   @return [String] The slug of the webhook endpoint for this payment method.
    delegate :slug,
      to: :webhook_endpoint,
      prefix: true

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

    def skip_confirm_step?
      preferred_stripe_intents_flow == 'payment' &&
        preferred_skip_confirmation_for_payment_intent
    end

    def payment_profiles_supported?
      # We actually support them, but not in the way expected by Solidus and its ActiveMerchant legacy.
      false
    end

    def intent_for_order(order)
      # TODO: See if we can move the intent creation out of the view
      intent_class.retrieve_stripe_intent(payment_method: self, order: order) ||
        intent_class.create_stripe_intent(payment_method: self, order: order)
    end

    def intent_class
      case preferred_stripe_intents_flow
      when 'setup' then SolidusStripe::SetupIntent
      when 'payment' then SolidusStripe::PaymentIntent
      end
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

    private

    def assign_webhook_endpoint
      create_webhook_endpoint!(
        slug: WebhookEndpoint.generate_slug
      )
    end
  end
end
