class SolidusStripe::PaymentIntentsController < ApplicationController
  def create
    payment_method = SolidusStripe::PaymentMethod.find(params[:payment_method_id])
    amount = current_order.total

    # Create a PaymentIntent with amount and currency
    payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: current_order.currency,
      automatic_payment_methods: {
        enabled: true,
      },
    )

    render json: { clientSecret: payment_intent['client_secret'] }
  end
end
