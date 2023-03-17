# frozen_string_literal: true

module SolidusStripe
  module Webhook
    # Handlers for Stripe payment_intent events.
    class PaymentIntentSubscriber
      include Omnes::Subscriber

      handle :"stripe.payment_intent.succeeded", with: :complete_payment

      # Captures a payment.
      #
      # Marks a Solidus payment associated to a Stripe payment intent as
      # completed, adding a log entry about the event.
      #
      # @param event [SolidusStripe::Webhook::Event]
      def complete_payment(event)
        payment_intent_id = event.data.object.id
        payment = Spree::Payment.find_by!(response_code: payment_intent_id)
        return if payment.completed?

        payment.complete!.tap do
          SolidusStripe::LogEntries.payment_log(
            payment,
            success: true,
            message: "Capture was successful after payment_intent.succeeded webhook"
          )
        end
      end
    end
  end
end
