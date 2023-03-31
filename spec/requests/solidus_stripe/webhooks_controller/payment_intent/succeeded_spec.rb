require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create payment_intent.succeeded" do
    it "captures the associated payment" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(
        id: "pi_123",
        amount: 1000,
        amount_received: 1000,
        currency: "usd"
      )
      payment = create(:payment,
        amount: 10,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      context = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.succeeded"
      )

      expect do
        webhook_request(context)
      end.to change { payment.reload.state }.from("pending").to("completed")
    end
  end
end
