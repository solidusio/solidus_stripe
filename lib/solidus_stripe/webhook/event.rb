# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Omnes event wrapping a Stripe event.
    #
    # All unknown methods are delegated to the wrapped Stripe event.
    #
    # @see Stripe::Event
    class Event
      include Omnes::Event

      PREFIX = "stripe."
      private_constant :PREFIX

      # TBD
      CORE_EVENTS = Set[*%i[]].freeze
      private_constant :CORE_EVENTS

      # @api private
      class << self
        def from_request(payload:, signature_header:, secret: default_secret, tolerance: default_tolerance)
          stripe_event = Stripe::Webhook.construct_event(payload, signature_header, secret, tolerance: tolerance)
          new(stripe_event: stripe_event)
        rescue Stripe::SignatureVerificationError, JSON::ParserError
          nil
        end

        def register(user_events:, bus:, core_events: CORE_EVENTS)
          (core_events + user_events).each do |event|
            bus.register(:"stripe.#{event}")
          end
        end

        private

        def default_tolerance
          SolidusStripe.configuration.webhook_signature_tolerance
        end

        def default_secret
          Rails.application.credentials.solidus_stripe[:webhook_endpoint_secret]
        end
      end

      # @api private
      attr_reader :omnes_event_name

      # @api private
      def initialize(stripe_event:)
        @stripe_event = stripe_event
        @omnes_event_name = :"#{PREFIX}#{stripe_event.type}"
      end

      # Serializable representation of the event.
      #
      # Ready to be consumed by async Omnes adapters, like
      # {Omnes::Subscriber::Adapter::ActiveJob} or
      # {Omnes::Subscriber::Adapter::Sidekiq}.
      #
      # @return [Hash<String, Object>]
      def payload
        @stripe_event.as_json
      end

      private

      def method_missing(method_name, ...)
        @stripe_event.send(method_name, ...)
      end

      def respond_to_missing?(...)
        @stripe_event.respond_to?(...)
      end
    end
  end
end
