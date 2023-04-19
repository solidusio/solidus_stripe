# frozen_string_literal: true

require "solidus_stripe/webhook/event"
require "stripe"

module SolidusStripe
  module Webhook
    # Factory to create a webhook event along with its context.
    #
    # It allows to create Stripe webhook from different sources (hash, stripe
    # object) in different representations (json, stripe event object, solidus
    # stripe object, header).
    #
    # The context for a event is composed by the timestamp and its secret, which
    # in turn affect the header representation.
    class EventWithContextFactory
      def self.from_data(data:, payment_method:, timestamp: Time.zone.now)
        new(data: data, timestamp: timestamp, payment_method: payment_method)
      end

      def self.from_object(object:, type:, payment_method:, timestamp: Time.zone.now)
        data_base = data_base(object, type)
        data = data_base.merge("webhook" => data_base)
        new(data: data, timestamp: timestamp, payment_method: payment_method)
      end

      def self.data_base(object, type)
        {
          "id" => "evt_3MRUo1JvEPu9yc7w091rP2XV",
          "object" => "event",
          "api_version" => "2022-11-15",
          "created" => 1_674_022_050,
          "data" => {
            "object" => object.as_json
          },
          "livemode" => false,
          "pending_webhooks" => 0,
          "request" => {
            "id" => "req_3MRUo1JvEPu9yc7w0",
            "idempotency_key" => "idempotency_key"
          },
          "type" => type
        }
      end
      private_class_method :data_base

      attr_reader :data, :timestamp, :secret, :payment_method

      def initialize(data:, payment_method:, timestamp: Time.zone.now)
        @data = data
        @timestamp = timestamp
        @payment_method = payment_method
        @secret = payment_method.preferred_webhook_endpoint_signing_secret
      end

      def stripe_object
        @stripe_object ||= Stripe::Event.construct_from(data)
      end

      def solidus_stripe_object
        @solidus_stripe_object = SolidusStripe::Webhook::Event.new(stripe_event: stripe_object,
          payment_method: @payment_method)
      end

      def json
        @json ||= JSON.generate(data)
      end

      def signature_header(timestamp: self.timestamp)
        @signature_header ||= Stripe::Webhook::Signature.generate_header(timestamp, signature)
      end

      def signature
        @signature ||= Stripe::Webhook::Signature.compute_signature(timestamp, json, secret)
      end

      def slug
        @payment_method.slug
      end
    end
  end
end
