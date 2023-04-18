# frozen_string_literal: true

require "solidus_stripe/refunds_synchronizer"

module SolidusStripe
  module Webhook
    # Handlers for Stripe payment_intent events.
    class PaymentIntentSubscriber
      include Omnes::Subscriber
      include SolidusStripe::MoneyToStripeAmountConverter

      handle :"stripe.payment_intent.succeeded", with: :capture_payment
      handle :"stripe.payment_intent.payment_failed", with: :fail_payment
      handle :"stripe.payment_intent.canceled", with: :void_payment

      # Captures a payment.
      #
      # Marks a Solidus payment associated to a Stripe payment intent as
      # completed, adding a log entry about the event.
      #
      # In the case of a partial capture, it also synchronizes the refunds.
      #
      # @param event [SolidusStripe::Webhook::Event]
      # @see SolidusStripe::RefundsSynchronizer
      def capture_payment(event)
        payment = extract_payment_from_event(event)
        payment.with_lock do
          break false if payment.completed?

          complete_payment(payment)
        end && sync_refunds(event)
      end

      # Fails a payment.
      #
      # Marks a Solidus payment associated to a Stripe payment intent as
      # failed, adding a log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def fail_payment(event)
        payment = extract_payment_from_event(event)

        payment.with_lock do
          break if payment.failed?

          payment.failure!.tap do
            SolidusStripe::LogEntries.payment_log(
              payment,
              success: false,
              message: "Payment was marked as failed after payment_intent.failed webhook"
            )
          end
        end
      end

      # Voids a payment.
      #
      # Voids a Solidus payment associated to a Stripe payment intent, adding a
      # log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def void_payment(event)
        payment = extract_payment_from_event(event)
        reason = event.data.object.cancellation_reason

        payment.with_lock do
          break if payment.void?

          payment.void!.tap do
            SolidusStripe::LogEntries.payment_log(
              payment,
              success: true,
              message: "Payment was voided after payment_intent.voided webhook (#{reason})"
            )
          end
        end
      end

      private

      def extract_payment_from_event(event)
        payment_intent_id = event.data.object.id
        Spree::Payment.find_by!(response_code: payment_intent_id)
      end

      def complete_payment(payment)
        payment.complete!.tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Capture was successful after payment_intent.succeeded webhook"
          )
        end
      end

      def sync_refunds(event)
        event.data.object.to_hash => {
          id: payment_intent_id,
          amount: stripe_amount,
          amount_received: stripe_amount_received,
          currency:
        }
        return if stripe_amount == stripe_amount_received

        payment_method = event.spree_payment_method
        RefundsSynchronizer
          .new(payment_method)
          .call(payment_intent_id)
      end
    end
  end
end
