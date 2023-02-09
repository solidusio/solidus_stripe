# frozen_string_literal: true

require 'stripe'

class SolidusStripe::PaymentIntentsController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  def create
    payment_method = current_order(create_order_if_necessary: true)
      .available_payment_methods.find(params[:payment_method_id])

    currency = current_order.currency
    amount = SolidusStripe::MoneyToStripeAmountConverter.to_stripe_amount(
      current_order.display_total.money.fractional,
      currency,
    )

    intent, _response = payment_method.gateway.client.request do
      Stripe::PaymentIntent.create({
        amount: amount,
        currency: currency,
        capture_method: 'manual',
      })
    end

    # TODO: send the payment source information to the frontend so
    # it can be used for the payment step form.
    _payment_source = SolidusStripe::PaymentSource.create!(
      stripe_payment_intent_id: intent.id,
      payment_method: payment_method,
    )

    render json: { client_secret: intent.client_secret }
  end
end
