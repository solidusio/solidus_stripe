require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create payment_intent.succeeded" do
    subject { webhook_request(context) }

    let(:payment_method) { create :solidus_stripe_payment_method }
    let(:stripe_payment_intent) {
      Stripe::PaymentIntent.construct_from(
        id: "pi_123",
        amount: 1000,
        amount_received: 1000,
        currency: "usd",
        payment_method: "pm_123"
      )
    }
    let(:payment) {
      create :solidus_stripe_payment,
        amount: 10,
        payment_method:,
        response_code: stripe_payment_intent.id,
        stripe_payment_method_id: "pm_123",
        state: "pending"
    }
    let(:context) {
      SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method:,
        object: stripe_payment_intent,
        type: "payment_intent.succeeded"
      )
    }

    it "captures the associated payment" do
      expect { subject }
        .to change { payment.reload.state }
        .from("pending").to("completed")
    end
  end
end
