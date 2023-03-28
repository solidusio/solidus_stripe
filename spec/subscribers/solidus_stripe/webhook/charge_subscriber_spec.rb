# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::Webhook::ChargeSubscriber do
  describe "#refund_payment" do
    it "creates a refund for a given payment" do
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
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_charge,
        type: "charge.refunded"
      ).solidus_stripe_object

      described_class.new.refund_payment(event)

      refund = payment.reload.refunds.last
      expect(refund).not_to be(nil)
      expect(refund.amount).to eq(5)
      expect(refund.transaction_id).to eq("pi_123")
      expect(refund.reason.name).to eq(SolidusStripe::Seeds::DEFAULT_STRIPE_REFUND_REASON_NAME)
    end

    it "deduces previously refunded amount" do
      SolidusStripe::Seeds.refund_reasons
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        amount: 10,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "completed")
      create(:refund, payment: payment, amount: 5)
      stripe_charge = Stripe::Charge.construct_from(id: "ch_123", payment_intent: "pi_123", amount_refunded: 700,
        currency: 'usd')
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_charge,
        type: "charge.refunded"
      ).solidus_stripe_object

      described_class.new.refund_payment(event)

      refund = payment.reload.refunds.last
      expect(refund.amount).to eq(2)
    end

    it "adds a log entry to the payment" do
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
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_charge,
        type: "charge.refunded"
      ).solidus_stripe_object

      described_class.new.refund_payment(event)

      details = payment.log_entries.last.parsed_details
      expect(details.success?).to be(true)
      expect(
        details.message
      ).to eq "Payment was refunded after charge.refunded webhook ($5.00)"
    end

    it "does nothing if the payment is already totally refunded" do
      SolidusStripe::Seeds.refund_reasons
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        amount: 10,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "completed")
      create(:refund, payment: payment, amount: 10)
      stripe_charge = Stripe::Charge.construct_from(id: "ch_123", payment_intent: "pi_123", amount_refunded: 1000,
        currency: 'usd')
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_charge,
        type: "charge.refunded"
      ).solidus_stripe_object

      described_class.new.refund_payment(event)

      expect(payment.reload.refunds.count).to be(1)
      expect(payment.log_entries.count).to be(0)
    end
  end
end
