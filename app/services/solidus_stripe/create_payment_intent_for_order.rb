# frozen_string_literal: true

module SolidusStripe
  class CreatePaymentIntentForOrder
    attr_reader :order, :payment_method_id, :stripe_payment_method_id

    def initialize(order_id:, payment_method_id:, stripe_payment_method_id:)
      @order = Spree::Order.find(order_id)
      @payment_method_id = payment_method_id
      @stripe_payment_method_id = stripe_payment_method_id
    end

    def call
      payment_method = SolidusStripe::PaymentMethod.find(payment_method_id)
      source = payment_source(payment_method: payment_method)

      payment = order.payments.create!(
        payment_method: payment_method,
        amount: order.order_total_after_store_credit,
        source: source
      )

      intent = SolidusStripe::PaymentIntent.prepare_for_payment(payment)

      { client_secret: intent.stripe_intent.client_secret }
    end

    private

    def payment_source(payment_method:)
      SolidusStripe::PaymentSource.find_or_create_by!(
        payment_method_id: payment_method.id,
        stripe_payment_method_id: stripe_payment_method_id
      )
    end
  end
end
