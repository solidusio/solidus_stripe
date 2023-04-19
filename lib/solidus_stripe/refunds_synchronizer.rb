# frozen_string_literal: true

require "solidus_stripe/money_to_stripe_amount_converter"

module SolidusStripe
  # Synchronizes refunds from Stripe to Solidus.
  #
  # For our use case, Stripe has two ways to inform us about refunds initiated
  # on their side:
  #
  # 1. The `charge.refunded` webhook event, which is triggered when a refund is
  # explicitly created.
  # 2. The `payment_intent.succeeded` webhook event, which is triggered when a
  # payment intent is captured. If the payment intent is captured for less than
  # the full amount, a refund is automatically created for the remaining amount.
  #
  # In both cases, Stripe doesn't tell us which refund was recently created, so
  # we need to fetch all the refunds for the payment intent and check if any of
  # them is missing on Solidus. We're using the `transaction_id` field on
  # `Spree::Refund` to match refunds against Stripe refunds ids. We could think
  # about only syncing the single refund not present on Solidus, but we need to
  # acknowledge concurrent partial refunds.
  #
  # The `Spree::RefundReason` with `SolidusStripe::Config.refund_reason_name`
  # as name is used as created refunds' reason.
  #
  # Besides, we need to account for refunds created from Solidus admin panel,
  # which calls the Stripe API. In this case, we need to avoid syncing the
  # refund back to Solidus on the subsequent webhook, otherwise we would end up
  # with duplicate records. We're marking those refunds with a metadata field on
  # Stripe, so we can filter them out (see {Gateway#credit}).
  class RefundsSynchronizer
    include MoneyToStripeAmountConverter

    # Metadata key used to mark refunds that shouldn't be synced back to Solidus.
    # @return [Symbol]
    SKIP_SYNC_METADATA_KEY = :solidus_skip_sync

    # Metadata value used to mark refunds that shouldn't be synced back to Solidus.
    # @return [String]
    SKIP_SYNC_METADATA_VALUE = 'true'

    # @param payment_method [SolidusStripe::PaymentMethod]
    def initialize(payment_method)
      @payment_method = payment_method
    end

    # @param stripe_payment_intent_id [String]
    def call(stripe_payment_intent_id)
      payment = @payment_method.payments.find_by!(response_code: stripe_payment_intent_id)

      stripe_refunds(stripe_payment_intent_id)
        .select(&method(:stripe_refund_needs_sync?))
        .map(
          &method(:create_refund).curry[payment]
        )
    end

    private

    def stripe_refunds(stripe_payment_intent_id)
      @payment_method.gateway.request do
        Stripe::Refund.list(payment_intent: stripe_payment_intent_id).data
      end
    end

    def stripe_refund_needs_sync?(stripe_refund)
      originated_outside_solidus = stripe_refund.metadata[SKIP_SYNC_METADATA_KEY] != SKIP_SYNC_METADATA_VALUE
      not_already_synced = Spree::Refund.find_by(transaction_id: stripe_refund.id).nil?

      originated_outside_solidus && not_already_synced
    end

    def create_refund(payment, stripe_refund)
      Spree::Refund.create!(
        payment: payment,
        amount: refund_decimal_amount(stripe_refund),
        transaction_id: stripe_refund.id,
        reason: SolidusStripe::PaymentMethod.refund_reason
      ).tap(&method(:log_refund).curry[payment])
    end

    def log_refund(payment, refund)
      SolidusStripe::LogEntries.payment_log(
        payment,
        success: true,
        message: "Payment was refunded after Stripe event (#{refund.money})"
      )
    end

    def refund_decimal_amount(stripe_refund)
      to_solidus_amount(stripe_refund.amount, stripe_refund.currency)
        .then { |amount| solidus_subunit_to_decimal(amount, stripe_refund.currency) }
    end
  end
end
