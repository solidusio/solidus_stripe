# frozen_string_literal: true

require 'stripe'

module SolidusStripe
  # @see https://stripe.com/docs/payments/accept-a-payment?platform=web&ui=checkout#auth-and-capture
  # @see https://stripe.com/docs/charges/placing-a-hold
  #
  # ## About fractional amounts
  #
  # All methods in the Gateway class will have `amount_in_cents` arguments representing the
  # fractional amount as defined by Spree::Money and will be translated to the fractional expected
  # by Stripe, although for most currencies it's cents some will have a different multiplier and
  # that is already took into account.
  #
  # @see SolidusStripe::MoneyToStripeAmountConverter
  class Gateway
    include SolidusStripe::MoneyToStripeAmountConverter
    include SolidusStripe::LogEntries

    def initialize(options)
      # Cannot use kwargs because of how the Gateway is initialized by Solidus.
      @client = Stripe::StripeClient.new(
        api_key: options.fetch(:api_key, nil),
      )
      @options = options
    end

    attr_reader :client

    # Captures a certain amount from a previously authorized transaction.
    #
    # @see https://stripe.com/docs/api/payment_intents/capture#capture_payment_intent
    # @see https://stripe.com/docs/payments/capture-later
    #
    # @todo add support for capturing custom amounts
    def capture(_amount_in_cents, _transaction_id, options = {})
      payment = options[:originator] or raise ArgumentError, "please provide a payment with the :originator option"
      payment_intent_id = payment.source.stripe_payment_intent_id

      raise ArgumentError, "missing transaction_id" unless payment_intent_id

      unless payment_intent_id.start_with?('pi_')
        raise ArgumentError, "the payment-intent id has the wrong format"
      end

      payment_intent = request { Stripe::PaymentIntent.capture(payment_intent_id) }

      build_payment_log(
        success: true,
        message: "Capture was successful",
        data: payment_intent,
      )
    rescue Stripe::InvalidRequestError => e
      build_payment_log(
        success: false,
        message: e.to_s,
        data: e.response,
      )
    end

    # Authorizes and captures a certain amount on the provided payment source.
    def purchase(amount_in_cents, _source, options = {})
      currency = options.fetch(:currency)

      # Charge the Customer instead of the card:
      payment_intent = request do
        Stripe::PaymentIntent.create({
          amount: to_stripe_amount(amount_in_cents, currency),
          currency: currency,
          **options[:payment_intent_options].to_h
        })
      end

      build_payment_log(
        success: true,
        message: "PaymentIntent was created successfully",
        data: payment_intent,
      )
    end

    # Voids a previously authorized transaction, releasing the funds that are on hold.
    def void(_transaction_id, source, _options = {})
      payment_intent = request do
        Stripe::PaymentIntent.cancel(source.stripe_payment_intent_id)
      end

      build_payment_log(
        success: true,
        message: "PaymentIntent was canceled successfully",
        data: payment_intent,
      )
    rescue Stripe::InvalidRequestError => e
      build_payment_log(
        success: false,
        message: e.to_s,
        data: e.response,
      )
    end

    # Refunds the provided amount on a previously captured transaction.
    def credit(amount_in_cents, _source, _transaction_id, options = {})
      refund = options[:originator]
      payment = refund.payment
      source = payment.source
      currency = payment.currency
      payment_intent_id = source.stripe_payment_intent_id

      stripe_refund = request do
        Stripe::Refund.create(
          amount: to_stripe_amount(amount_in_cents, currency),
          payment_intent: payment_intent_id,
        )
      end

      build_payment_log(
        success: true,
        message: "PaymentIntent was refunded successfully",
        data: stripe_refund,
      )
    end

    # Send a request to stripe using the current api keys but ignoring
    # the response object.
    #
    # @yield Allows to use the `Stripe` gem using the credentials attached
    #   to the current payment method
    #
    # @example Retrieve a payment intent
    #   request { Stripe::PaymentIntent.retrieve(intent_id) }
    #
    # @return forwards the result of the block
    def request(&block)
      result, _response = client.request(&block)
      result
    end
  end
end
