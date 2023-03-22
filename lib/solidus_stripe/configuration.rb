# frozen_string_literal: true

require "stripe/webhook"
require "solidus_stripe/payment_flow_strategy"

module SolidusStripe
  class Configuration
    # @!attribute [rw] payment_flow_strategy
    #  @return [] A callable returning a payment strategy for the given order
    attr_accessor :payment_flow_strategy

    # @!attribute [rw] webhook_events
    #  @return [Array<Symbol>] stripe events to handle. You also need to
    #  register them in the Stripe dashboard. For an event `:foo`, a matching
    #  `:"stripe.foo"` event will be registered in `Spree::Bus`.
    attr_accessor :webhook_events

    # @!attribute [rw] webhook_signature_tolerance
    #  @return [Integer] number of seconds while a webhook event is valid after
    #  its creation. Defaults to `Stripe::Webhook::DEFAULT_TOLERANCE`.
    attr_accessor :webhook_signature_tolerance

    def initialize
      @payment_flow_strategy = SolidusStripe::PaymentFlowStrategy::SetupIntent
      @webhook_events = []
      @webhook_signature_tolerance = Stripe::Webhook::DEFAULT_TOLERANCE
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration
      @reset_configuration = nil
    end

    alias config configuration

    def configure
      yield configuration
    end
  end
end
