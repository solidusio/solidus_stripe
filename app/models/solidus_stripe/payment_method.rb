# frozen_string_literal: true

module SolidusStripe
  class PaymentMethod < ::Spree::PaymentMethod
    preference :api_key, :string
    preference :publishable_key, :string
    preference :setup_future_usage, :string, default: ''

    # @attribute [rw] preferred_webhook_endpoint_signing_secret The webhook endpoint signing secret
    #  for this payment method.
    # @see https://stripe.com/docs/webhooks/signatures
    preference :webhook_endpoint_signing_secret, :string

    validates :available_to_admin, inclusion: { in: [false] }
    validates :preferred_setup_future_usage, inclusion: { in: ['', 'on_session', 'off_session'] }

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

    def payment_profiles_supported?
      # We actually support them, but not in the way expected by Solidus and its ActiveMerchant legacy.
      false
    end

    def intent_for_order(order)
      # TODO: See if we can move the intent creation out of the view
      SolidusStripe::PaymentIntent.retrieve_stripe_intent(payment_method: self, order: order) ||
        SolidusStripe::PaymentIntent.create_stripe_intent(payment_method: self, order: order)
    end

    # TODO: re-evaluate the need for this and think of ways to always go throught the intent classes.
    def self.intent_id_for_payment(payment)
      return unless payment

      payment.transaction_id || SolidusStripe::PaymentIntent.where(
        order: payment.order, payment_method: payment.payment_method
      )&.pick(:stripe_intent_id)
    end

    def stripe_dashboard_url(intent_id)
      path_prefix = '/test' if preferred_test_mode

      case intent_id
      when /^pi_/
        "https://dashboard.stripe.com#{path_prefix}/payments/#{intent_id}"
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
