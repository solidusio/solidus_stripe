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

      # We can have multiple payments for the same payment intent, so we need to
      # find the one that matches the payment method used in the event not just
      # the one that matches the response code.
      #
      # This may run into issues in the future with reusable payment methods,
      # since we could theoretically have multiple payments with the same intent
      # and source.
      def extract_payment_from_event(event)
        stripe_payment_intent_id = event.data.object.id
        stripe_payment_method_id = event.data.object.payment_method

        stripe_source_arel = SolidusStripe::PaymentSource.arel_table
        payment_arel = Spree::Payment.arel_table
        Spree::Payment.joins(
          payment_arel.join(stripe_source_arel).on(
            stripe_source_arel[:id].eq(payment_arel[:source_id]).and(payment_arel[:source_type].eq('SolidusStripe::PaymentSource'))
          ).join_sources
        ).find_by!(response_code: stripe_payment_intent_id, solidus_stripe_payment_sources: { stripe_payment_method_id: })
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
          id: stripe_payment_intent_id,
          amount: stripe_amount,
          amount_received: stripe_amount_received,
          currency:
        }
        return if stripe_amount == stripe_amount_received

        payment_method = event.payment_method
        RefundsSynchronizer
          .new(payment_method)
          .call(stripe_payment_intent_id)
      end
    end
  end
end
