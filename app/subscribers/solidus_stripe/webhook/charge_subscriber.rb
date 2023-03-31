# frozen_string_literal: true

require "solidus_stripe/money_to_stripe_amount_converter"

module SolidusStripe
  module Webhook
    # Handlers for Stripe charge events.
    class ChargeSubscriber
      include Omnes::Subscriber
      include MoneyToStripeAmountConverter

      handle :"stripe.charge.refunded", with: :refund_payment

      # Refunds a payment.
      #
      # Creates a `Spree::Refund` for the payment associated with the
      # webhook event.
      #
      # The event's `amount_refunded` field on Stripe contains the total amount
      # refunded for the payment, including previous ones. We need to check that
      # against the last total refunded amount on the payment to get the actual
      # amount refunded by the current event.
      #
      # The `Spree::RefundReason` with `SolidusStripe::Config.refund_reason_name`
      # as name is used as the created refund's reason.
      #
      # Notice that, at this point, we have no way to distinguish between
      # multiple occurrences of the same event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def refund_payment(event)
        event.data.object.to_hash => {
          amount_refunded: new_stripe_total,
          payment_intent: payment_intent_id,
          currency:
        }
        payment = Spree::Payment.find_by!(response_code: payment_intent_id)

        return if payment.fully_refunded?

        amount = refund_amount(new_stripe_total, currency, payment)
        Spree::Refund.create!(
          payment: payment,
          amount: amount,
          transaction_id: payment_intent_id,
          reason: default_refund_reason
        ).tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Payment was refunded after charge.refunded webhook (#{_1.money})"
          )
        end
      end

      private

      def default_refund_reason
        Spree::RefundReason.find_by!(
          name: SolidusStripe.configuration.refund_reason_name
        )
      end

      def refund_amount(new_stripe_total, currency, payment)
        last_total = payment.refunds.sum(:amount)

        new_stripe_total
          .then { to_solidus_amount(_1, currency) }
          .then { _1 - solidus_decimal_to_subunit(last_total, currency) }
          .then { solidus_subunit_to_decimal(_1, currency) }
      end
    end
  end
end
