# frozen_string_literal: true

require "solidus_stripe/money_to_stripe_amount_converter"

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
      # In the case of a partial capture, a refund is created for the
      # remaining amount and a log entry is added.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def capture_payment(event)
        payment = extract_payment_from_event(event)
        return if payment.completed?

        event.data.object.to_hash => {
          amount: stripe_amount,
          amount_received: stripe_amount_received,
          currency:
        }
        if stripe_amount == stripe_amount_received
          complete_payment(payment)
        else
          payment.transaction do
            complete_payment(payment)
            refund_payment(payment, stripe_amount, stripe_amount_received, currency)
          end
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

      # Voids a payment.
      #
      # Voids a Solidus payment associated to a Stripe payment intent, adding a
      # log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def void_payment(event)
        payment = extract_payment_from_event(event)
        return if payment.void?

        reason = event.data.object.cancellation_reason
        payment.void!.tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Payment was voided after payment_intent.voided webhook (#{reason})"
          )
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

      def refund_payment(payment, stripe_amount, stripe_amount_received, currency)
        refunded_amount = decimal_amount(stripe_amount - stripe_amount_received, currency)
        Spree::Refund.create!(
          payment: payment,
          amount: refunded_amount,
          transaction_id: payment.response_code,
          reason: SolidusStripe::PaymentMethod.refund_reason
        ).tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Payment was refunded after payment_intent.succeeded webhook (#{_1.money})"
          )
        end
      end

      def decimal_amount(stripe_amount, currency)
        stripe_amount
          .then { to_solidus_amount(_1, currency) }
          .then { solidus_subunit_to_decimal(_1, currency) }
      end
    end
  end
end
