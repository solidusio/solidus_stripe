# frozen_string_literal: true

module SolidusStripe
  class PaymentIntent < ApplicationRecord
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :payment_method, class_name: 'SolidusStripe::PaymentMethod'

    def self.retrieve_stripe_intent(payment_method:, order:)
      find_by(payment_method: payment_method, order: order)&.stripe_intent
    end

    def self.create_stripe_intent(payment_method:, order:, stripe_intent_options: {})
      instance = new(payment_method: payment_method, order: order)
      instance.create_stripe_intent(stripe_intent_options).tap { instance.update!(stripe_intent_id: _1.id) }
    end

    def stripe_intent
      payment_method.gateway.request do
        Stripe::PaymentIntent.retrieve(stripe_intent_id)
      end
    end

    def create_payment!(amount: order.total, add_to_wallet: false)
      payment = order.payments.create!(
        state: 'pending',
        payment_method: payment_method,
        amount: amount,
        response_code: stripe_intent.id,
        source: payment_method.payment_source_class.new(
          payment_method: payment_method,
        ),
      )

      if add_to_wallet && order.user && stripe_intent.setup_future_usage.present?
        payment.source.update!(stripe_payment_method_id: stripe_intent.payment_method)
        order.user.wallet.add payment.source
      end

      payment
    end

    def create_stripe_intent(stripe_intent_options)
      stripe_customer_id = SolidusStripe::Customer.retrieve_or_create_stripe_customer_id(
        payment_method: payment_method,
        order: order
      )

      payment_method.gateway.request do
        Stripe::PaymentIntent.create({
          amount: payment_method.gateway.to_stripe_amount(
            order.display_total.money.fractional,
            order.currency,
          ),
          currency: order.currency,

          # The capture method should stay manual in order to
          # avoid capturing the money before the order is completed.
          capture_method: 'manual',
          customer: stripe_customer_id,
          metadata: { solidus_order_number: order.number },
        }.merge(stripe_intent_options))
      end
    end
  end
end
