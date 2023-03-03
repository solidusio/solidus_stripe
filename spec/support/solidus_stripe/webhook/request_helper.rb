# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Helpers to simulate incoming Stripe webhook from request specs.
    #
    # It's a lightweight alternative to configuring `stripe-cli` in the automated tests.
    module RequestHelper
      # @param context [SolidusStripe::Webhook::EventWithContextFactory]
      # @param timestamp [Time] It allows to override the timestamp in the context
      #   to simulate an invalid request.
      def webhook_request(context, timestamp: context.timestamp)
        stub_webhook_endpoint_secret(context.secret)

        post "/solidus_stripe/webhooks",
          params: context.json,
          headers: { webhook_signature_header_key => webhook_signature_header(context, timestamp: timestamp) }
      end

      private

      def webhook_signature_header_key
        SolidusStripe::WebhooksController::SIGNATURE_HEADER
      end

      def webhook_signature_header(context, timestamp:)
        context.signature_header(timestamp: timestamp)
      end

      def stub_webhook_endpoint_secret(secret)
        allow(Rails.application.credentials).to receive(:solidus_stripe)
          .and_return({ webhook_endpoint_secret: secret })
      end
    end
  end
end
