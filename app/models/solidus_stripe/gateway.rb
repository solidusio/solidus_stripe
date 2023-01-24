# frozen_string_literal: true

require 'stripe'

# Documentation about separate authorization and capture
# - https://stripe.com/docs/payments/accept-a-payment?platform=web&ui=checkout#auth-and-capture
# - https://stripe.com/docs/charges/placing-a-hold
module SolidusStripe
  class Gateway
    def initialize(options)
      # Cannot use kwargs because of how the Gateway is initialized by Solidus.
      @client = Stripe::StripeClient.new(
        api_key: options.fetch(:api_key, nil),
      )
      @options = options
    end

    attr_reader :client

    # Authorizes a certain amount on the provided payment source.
    #
    # @see #purchase
    def authorize(amount_in_cents, source, options = {})
      payment_intent_options = options[:payment_intent_options].dup.to_h
      payment_intent_options[:capture_method] = "manual"
      purchase(amount_in_cents, source, options.merge(payment_intent_options: payment_intent_options))
    end

    # Captures a certain amount from a previously authorized transaction.
    # Ref: https://stripe.com/docs/api/payment_intents/capture#capture_payment_intent
    # Ref: https://stripe.com/docs/payments/capture-later
    #
    # @todo add support for capturing custom amounts
    #
    # @param _amount_in_cents [Integer] The fractional amount as defined by Spree::Money,
    #   although it's cents for most currencies some will have a different multiplier.
    #   Currently ignored (see "todo" section).
    # @param _transaction_id [Object] (currently ignored)
    # @param options [Hash]
    # @option options [Spree::Payment] :originator the payment on which the #capture is being performed (required)
    #
    # @return ActiveMerchant::Billing::Response
    def capture(_amount_in_cents, _transaction_id, options = {})
      payment = options[:originator] or raise ArgumentError, "please provide a payment with the :originator option"
      payment_intent_id = payment.source.stripe_payment_intent_id

      raise ArgumentError, "missing transaction_id" unless payment_intent_id

      unless payment_intent_id.start_with?('pi_')
        raise ArgumentError, "the payment-intent id has the wrong format"
      end

      payment_intent, _response = client.request { Stripe::PaymentIntent.capture(payment_intent_id) }

      ActiveMerchant::Billing::Response.new(
        true, "Capture was successful", { 'stripe_payment_intent' => payment_intent.to_json }, {}
      )
    rescue Stripe::InvalidRequestError => e
      ActiveMerchant::Billing::Response.new(
        false, e.to_s, { 'json_response' => e.response.to_json }, {}
      )
    end

    # Authorizes and captures a certain amount on the provided payment source.
    #
    # @param amount_in_cents [Integer] The fractional amount as defined by Spree::Money,
    #   although it's cents for most currencies some will have a different multiplier.
    # @param source [Spree::PaymentSource, nil] optionally, payment source from which to create the authorization
    # @param options [Hash]
    # @option options [Hash] :payment_intent_options options forwarded to `Stripe::PaymentIntent.create`
    #
    # @return ActiveMerchant::Billing::Response
    def purchase(amount_in_cents, _source, options = {})
      currency = options.fetch(:currency)

      # Charge the Customer instead of the card:
      payment_intent, _response = client.request do
        Stripe::PaymentIntent.create({
          amount: MoneyToStripeAmountConverter.to_stripe_amount(amount_in_cents, currency),
          currency: currency,
          **options[:payment_intent_options].to_h
        })
      end

      ActiveMerchant::Billing::Response.new(
        true, "PaymentIntent was created successfully", { 'stripe_payment_intent' => payment_intent.to_json }, {}
      )
    end

    # Voids a previously authorized transaction, releasing the funds that are on hold.
    # The source parameter is only needed for payment gateways that support payment profiles.
    #
    # @param _transaction_id [Object] (currently ignored)
    # @param source [Spree::PaymentSource, nil] optionally, payment source from which to create the authorization
    # @param _options [Hash] (ignored)
    #
    # @return ActiveMerchant::Billing::Response
    def void(_transaction_id, source, _options = {})
      payment_intent, _response = client.request do
        Stripe::PaymentIntent.cancel(source.stripe_payment_intent_id)
      end

      ActiveMerchant::Billing::Response.new(
        true, "PaymentIntent was canceled successfully", { 'stripe_payment_intent' => payment_intent.to_json }, {}
      )
    rescue Stripe::InvalidRequestError => e
      ActiveMerchant::Billing::Response.new(
        false, e.to_s, { 'json_response' => e.response.to_json }, {}
      )
    end

    # Refunds the provided amount on a previously captured transaction.
    # The source parameter is only needed for payment gateways that support payment profiles.
    #
    # @param amount_in_cents [Integer] The fractional amount as defined by Spree::Money,
    #   although it's cents for most currencies some will have a different multiplier.
    # @param source [Spree::PaymentSource, nil] optionally, payment source from which
    #   to create the authorization
    # @param _transaction_id [Object] (currently ignored)
    # @param options [Hash]
    # @option options [Spree::Payment] :originator the payment on which the #capture is
    #   being performed (required if source is nil)
    #
    # @return ActiveMerchant::Billing::Response
    def credit(amount_in_cents, source, _transaction_id, options = {})
      currency = options.fetch(:currency)
      source ||= options[:originator].source

      refund, _response = client.request do
        Stripe::Refund.create(
          amount: MoneyToStripeAmountConverter.to_stripe_amount(amount_in_cents, currency),
          payment_intent: source.stripe_payment_intent_id,
        )
      end

      ActiveMerchant::Billing::Response.new(
        true, "PaymentIntent was refunded successfully", { 'stripe_refund' => refund.to_json }, {}
      )
    end

    module MoneyToStripeAmountConverter
      extend self

      ZERO_DECIMAL_CURRENCIES = %w[
        BIF
        CLP
        DJF
        GNF
        JPY
        KMF
        KRW
        MGA
        PYG
        RWF
        UGX
        VND
        VUV
        XAF
        XOF
        XPF
      ].freeze

      THREE_DECIMAL_CURRENCIES = %w[
        BHD
        JOD
        KWD
        OMR
        TND
      ].freeze

      # special currencies that are represented in cents but
      # should be divisible by 100, thus making them integer only.
      DIVISIBLE_BY_100 = %w[
        HUF
        TWD
        UGX
      ].freeze

      # Solidus will provide a "fractional" amount, that is specific for each currency
      # following the configurationo defined in the Money gem.
      #
      # Stripe uses the "smallest currency unit",
      # (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency)
      # https://stripe.com/docs/currencies#zero-decimal
      #
      # We need to ensure the fractional amount is considering the same number of decimals.
      def to_stripe_amount(fractional, currency)
        money_subunit_to_unit = ::Money::Currency.new(currency).subunit_to_unit
        stripe_subunit_to_unit =
          case currency.to_s.upcase
          when *ZERO_DECIMAL_CURRENCIES then 1
          when *THREE_DECIMAL_CURRENCIES then 1000
          when *DIVISIBLE_BY_100 then 100
          else 100
          end

        if stripe_subunit_to_unit == money_subunit_to_unit
          fractional
        else
          (fractional / money_subunit_to_unit.to_d) * stripe_subunit_to_unit
        end
      end
    end
  end
end
