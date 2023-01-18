# frozen_string_literal: true

require "stripe/webhook"

module SolidusStripe
  class Configuration
    # @!attribute [rw] webhook_events
    #  @return [Array<Symbol>] stripe events to handle. You also need to
    #  register them in the Stripe dashboard. For an event `:foo`, a matching
    #  `:"stripe.foo"` event will be registered in {Spree::Bus}.
    attr_accessor :webhook_events

    # @!attribute [rw] webhook_signature_tolerance
    #  @return [Integer] number of seconds while a webhook event is valid after
    #  its creation. Defaults to {Stripe::Webhook::DEFAULT_TOLERANCE}.
    attr_accessor :webhook_signature_tolerance

    def initialize
      @webhook_events = []
      @webhook_signature_tolerance = Stripe::Webhook::DEFAULT_TOLERANCE
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
    end
  end
end
