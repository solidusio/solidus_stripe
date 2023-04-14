# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::Webhook::PaymentIntentSubscriber do
  describe "#capture_payment" do
    context "when a full capture is performed" do
      it "completes a pending payment" do
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
        event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
          payment_method: payment_method,
          object: stripe_payment_intent,
          type: "payment_intent.succeeded"
        ).solidus_stripe_object

        described_class.new.capture_payment(event)

        expect(payment.reload.state).to eq "completed"
      end

      it "adds a log entry to the payment" do
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
        event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
          payment_method: payment_method,
          object: stripe_payment_intent,
          type: "payment_intent.succeeded"
        ).solidus_stripe_object

        described_class.new.capture_payment(event)

        details = payment.log_entries.last.parsed_details
        expect(details.success?).to be(true)
        expect(
          details.message
        ).to eq "Capture was successful after payment_intent.succeeded webhook"
      end
    end

    context "when a partial capture is performed" do
      it "completes a pending payment" do
        SolidusStripe::Seeds.refund_reasons
        payment_method = create(:stripe_payment_method)
        stripe_payment_intent = Stripe::PaymentIntent.construct_from(
          id: "pi_123",
          amount: 1000,
          amount_received: 700,
          currency: "usd"
        )
        payment = create(:payment,
          amount: 10,
          payment_method: payment_method,
          response_code: stripe_payment_intent.id,
          state: "pending")
        allow(Stripe::Refund).to receive(:list).with(payment_intent: stripe_payment_intent.id).and_return(
          Stripe::ListObject.construct_from(
            data: [{ id: "re_123", amount: 700, currency: "usd", metadata: {} }]
          )
        )
        event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
          payment_method: payment_method,
          object: stripe_payment_intent,
          type: "payment_intent.succeeded"
        ).solidus_stripe_object

        described_class.new.capture_payment(event)

        expect(payment.reload.state).to eq "completed"
      end

      it "synchronizes refunds" do
        SolidusStripe::Seeds.refund_reasons
        payment_method = create(:stripe_payment_method)
        stripe_payment_intent = Stripe::PaymentIntent.construct_from(
          id: "pi_123",
          amount: 1000,
          amount_received: 700,
          currency: "usd"
        )
        payment = create(:payment,
          amount: 7,
          payment_method: payment_method,
          response_code: stripe_payment_intent.id,
          state: "pending")
        allow(Stripe::Refund).to receive(:list).with(payment_intent: stripe_payment_intent.id).and_return(
          Stripe::ListObject.construct_from(
            data: [{ id: "re_123", amount: 200, currency: "usd", metadata: {} }]
          )
        )
        event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
          payment_method: payment_method,
          object: stripe_payment_intent,
          type: "payment_intent.succeeded"
        ).solidus_stripe_object

        described_class.new.capture_payment(event)

        expect(payment.refunds.count).to be(1)
      end

      it "adds a log entry for the captured payment" do
        SolidusStripe::Seeds.refund_reasons
        payment_method = create(:stripe_payment_method)
        stripe_payment_intent = Stripe::PaymentIntent.construct_from(
          id: "pi_123",
          amount: 1000,
          amount_received: 700,
          currency: "usd"
        )
        payment = create(:payment,
          amount: 10,
          payment_method: payment_method,
          response_code: stripe_payment_intent.id,
          state: "pending")
        allow(Stripe::Refund).to receive(:list).with(payment_intent: stripe_payment_intent.id).and_return(
          Stripe::ListObject.construct_from(
            data: [{ id: "re_123", amount: 700, currency: "usd", metadata: {} }]
          )
        )
        event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
          payment_method: payment_method,
          object: stripe_payment_intent,
          type: "payment_intent.succeeded"
        ).solidus_stripe_object

        described_class.new.capture_payment(event)

        log_entries = payment.log_entries.map { [_1.parsed_details.success?, _1.parsed_details.message] }
        expect(
          log_entries
        ).to include([true, "Capture was successful after payment_intent.succeeded webhook"])
      end
    end

    it "does nothing if the payment is already completed" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "completed")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.succeeded",
      ).solidus_stripe_object

      described_class.new.capture_payment(event)

      expect(payment.reload.state).to eq "completed"
      expect(payment.log_entries.count).to be(0)
    end
  end

  describe "#fail_payment" do
    it "fails a pending payment" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.payment_failed"
      ).solidus_stripe_object

      described_class.new.fail_payment(event)

      expect(payment.reload.state).to eq "failed"
    end

    it "adds a log entry to the payment" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.payment_failed"
      ).solidus_stripe_object

      described_class.new.fail_payment(event)

      details = payment.log_entries.last.parsed_details
      expect(details.success?).to be(false)
      expect(
        details.message
      ).to eq "Payment was marked as failed after payment_intent.failed webhook"
    end

    it "does nothing if the payment is already failed" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "failed")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.payment_failed",
      ).solidus_stripe_object

      described_class.new.fail_payment(event)

      expect(payment.reload.state).to eq "failed"
      expect(payment.log_entries.count).to be(0)
    end
  end

  describe "#void_payment" do
    it "voids a pending payment" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123", cancellation_reason: "duplicate")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.canceled"
      ).solidus_stripe_object

      described_class.new.void_payment(event)

      expect(payment.reload.state).to eq "void"
    end

    it "adds a log entry to the payment" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123", cancellation_reason: "duplicate")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "pending")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.canceled"
      ).solidus_stripe_object

      described_class.new.void_payment(event)

      details = payment.log_entries.last.parsed_details
      expect(details.success?).to be(true)
      expect(
        details.message
      ).to eq "Payment was voided after payment_intent.voided webhook (duplicate)"
    end

    it "does nothing if the payment is already voided" do
      payment_method = create(:stripe_payment_method)
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      payment = create(:payment,
        payment_method: payment_method,
        response_code: stripe_payment_intent.id,
        state: "void")
      event = SolidusStripe::Webhook::EventWithContextFactory.from_object(
        payment_method: payment_method,
        object: stripe_payment_intent,
        type: "payment_intent.payment_void",
      ).solidus_stripe_object

      described_class.new.void_payment(event)

      expect(payment.reload.state).to eq "void"
      expect(payment.log_entries.count).to be(0)
    end
  end
end
