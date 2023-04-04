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

    has_one :slug_entry, class_name: 'SolidusStripe::SlugEntry', inverse_of: :payment_method, dependent: :destroy

    after_create :assign_slug

    delegate :slug, to: :slug_entry

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

    def assign_slug
      create_slug_entry!(slug: SlugEntry.generate_slug)
    end
  end
end
