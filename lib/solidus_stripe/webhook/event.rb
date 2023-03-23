# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Omnes event wrapping a Stripe event for a given payment method.
    #
    # All unknown methods are delegated to the wrapped Stripe event.
    #
    # @see https://www.rubydoc.info/gems/stripe/Stripe/Event
    class Event
      include Omnes::Event

      PREFIX = "stripe."
      private_constant :PREFIX

      CORE_EVENTS = Set[*%i[
        payment_intent.succeeded
        payment_intent.payment_failed
      ]].freeze
      private_constant :CORE_EVENTS

      # @api private
      class << self
        def from_request(payload:, signature_header:, slug:, tolerance: default_tolerance)
          payment_method = SolidusStripe::WebhookEndpoint.payment_method(slug)
          stripe_event = Stripe::Webhook.construct_event(
            payload,
            signature_header,
            payment_method.preferred_webhook_endpoint_signing_secret,
            tolerance: tolerance
          )
          new(stripe_event: stripe_event, spree_payment_method: payment_method)
        rescue ActiveRecord::RecordNotFound, Stripe::SignatureVerificationError, JSON::ParserError
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
      end

      # @api private
      attr_reader :omnes_event_name

      # @attr_reader [SolidusStripe::PaymentMethod]
      attr_reader :spree_payment_method

      # @api private
      def initialize(stripe_event:, spree_payment_method:)
        @stripe_event = stripe_event
        @spree_payment_method = spree_payment_method
        @omnes_event_name = :"#{PREFIX}#{stripe_event.type}"
      end

      # Serializable representation of the event.
      #
      # Ready to be consumed by async Omnes adapters, like
      # `Omnes::Subscriber::Adapter::ActiveJob` or
      # `Omnes::Subscriber::Adapter::Sidekiq`.
      #
      # @return [Hash<String, Object>]
      def payload
        {
          "stripe_event" => @stripe_event.as_json,
          "spree_payment_method_id" => @spree_payment_method.id
        }
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
