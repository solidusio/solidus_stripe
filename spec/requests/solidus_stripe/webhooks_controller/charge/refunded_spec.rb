require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create charge.refunded" do
    it "creates a refund for the given payment" do
      SolidusStripe::Seeds.refund_reasons
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        amount: 10,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "completed")
      stripe_charge = Stripe::Charge.construct_from(id: "ch_123", payment_intent: "pi_123", amount_refunded: 500,
        currency: 'usd')
      context = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_charge,
        type: "charge.refunded"
      )

      webhook_request(context)

      expect(payment.reload.refunds.count).to be(1)
    end
  end
end
