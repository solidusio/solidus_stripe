# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Handlers for Stripe payment_intent events.
    class PaymentIntentSubscriber
      include Omnes::Subscriber

      handle :"stripe.payment_intent.succeeded", with: :complete_payment
      handle :"stripe.payment_intent.payment_failed", with: :fail_payment

      # Captures a payment.
      #
      # Marks a Solidus payment associated to a Stripe payment intent as
      # completed, adding a log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def complete_payment(event)
        payment = extract_payment_from_event(event)
        return if payment.completed?

        payment.complete!.tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Capture was successful after payment_intent.succeeded webhook"
          )
        end
      end

      # Fails a payment.
      #
      # Marks a Solidus payment associated to a Stripe payment intent as
      # failed, adding a log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def fail_payment(event)
        payment = extract_payment_from_event(event)
        return if payment.failed?

        payment.failure!.tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: false,
            message: "Payment was marked as failed after payment_intent.failed webhook"
          )
        end
      end

      private

      def extract_payment_from_event(event)
        payment_intent_id = event.data.object.id
        Spree::Payment.find_by!(response_code: payment_intent_id)
      end
    end
  end
end
