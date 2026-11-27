require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create payment_intent.canceled" do
    subject { webhook_request(context) }

    let(:payment_method) { create :solidus_stripe_payment_method }
    let(:stripe_payment_intent) {
      Stripe::PaymentIntent.construct_from(
        id: "pi_123",
        cancellation_reason: "duplicate",
        payment_method: "pm_123"
      )
    }
    let(:payment) {
      create :solidus_stripe_payment,
        payment_method:,
        response_code: stripe_payment_intent.id,
        stripe_payment_method_id: "pm_123",
        state: "pending"
    }
    let(:context) {
      SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method:,
        object: stripe_payment_intent,
        type: "payment_intent.canceled"
      )
    }

    it "transitions the associated payment to void" do
      expect { subject }
        .to change { payment.reload.state }
        .from("pending").to("void")
    end
  end
end
