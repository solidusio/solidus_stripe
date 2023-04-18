require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::WebhooksController, type: %i[request webhook_request] do
  describe "POST /create charge.refunded" do
    it "synchronizes refunds" do
      SolidusStripe::Seeds.refund_reasons
      payment_method = create(:solidus_stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        amount: 10,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "completed")
      stripe_charge = Stripe::Charge.construct_from(id: "ch_123", payment_intent: "pi_123")
      allow(Stripe::Refund).to receive(:list).with(payment_intent: stripe_payment_intent.id).and_return(
        Stripe::ListObject.construct_from(
          data: [{ id: "re_123", amount: 1000, currency: "usd", metadata: {} }]
        )
      )
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
