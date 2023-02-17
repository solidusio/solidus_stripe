# frozen_string_literal: true

require "solidus_stripe/webhook/event"
require "stripe"

module SolidusStripe
  module Webhook
    # Factory to create a webhook event along with its context.
    #
    # It allows to create Stripe webhook from different sources (hash, stripe
    # object) in different representations (json, stripe event object, header).
    #
    # The context for a event is composed by the timestamp and its secret, which
    # in turn affect the header representation.
    class EventWithContextFactory
      def self.from_data(data:, timestamp: Time.zone.now, secret: "whsec_123")
        new(data: data, timestamp: timestamp, secret: secret)
      end

      def self.from_object(object:, type:, timestamp: Time.zone.now, secret: "whsec_123")
        data_base = data_base(object, type)
        data = data_base.merge("webhook" => data_base)
        new(data: data, timestamp: timestamp, secret: secret)
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

      attr_reader :data, :timestamp, :secret

      def initialize(data:, timestamp: Time.zone.now, secret: "whsec_123")
        @data = data
        @timestamp = timestamp
        @secret = secret
      end

      def stripe_object
        @stripe_object ||= Stripe::Event.construct_from(data)
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
    end
  end
end
