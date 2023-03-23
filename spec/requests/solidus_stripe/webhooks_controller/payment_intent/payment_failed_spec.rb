require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create payment_intent.payment_failed" do
    it "transitions the associated payment to failed" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      context = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.payment_failed"
      )

      expect do
        webhook_request(context)
      end.to change { payment.reload.state }.from("pending").to("failed")
    end
  end
end
