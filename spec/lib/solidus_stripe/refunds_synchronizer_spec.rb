# frozen-string-literal: true

require "solidus_stripe_spec_helper"
require "solidus_stripe/refunds_synchronizer"
require "solidus_stripe/seeds"

RSpec.describe SolidusStripe::RefundsSynchronizer do
  def mock_refund_list(payment_intent_id, refunds)
    allow(Stripe::Refund).to receive(:list).with(payment_intent: payment_intent_id).and_return(
      Stripe::ListObject.construct_from(
        data: refunds
      )
    )
  end

  describe "#call" do
    let(:payment_method) { create(:solidus_stripe_payment_method) }

    it "creates missing refunds on Solidus" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.refunds.count).to eq(1)
    end

    it "uses the stripe refund id as created Solidus refund transaction_id field" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      refund = payment.refunds.first
      expect(refund.transaction_id).to eq("re_123")
    end

    it "uses the stripe amount as created Solidus refund amount" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      refund = payment.refunds.first
      expect(refund.amount).to eq(10)
    end

    it "uses the configured reason for created Solidus refunds" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      refund = payment.refunds.first
      expect(refund.reason).to eq(SolidusStripe::PaymentMethod.refund_reason)
    end

    it "skips the creation of Solidus refunds with transaction_id matching some stripe refund id" do
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])
      create(:refund, amount: 10, payment: payment, transaction_id: "re_123")

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.refunds.count).to be(1)
    end

    it "skips the creation of Solidus refunds when specified in their metadata" do
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {
            solidus_skip_sync: 'true'
          }
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.refunds.count).to be(0)
    end

    it "creates multiple Solidus refunds if needed" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 500,
          currency: "usd",
          metadata: {}
        },
        {
          id: "re_456",
          amount: 500,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.refunds.count).to be(2)
    end

    it "creates only the missing Solidus refunds when there're multiple Stripe refunds" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 500,
          currency: "usd",
          metadata: {}
        },
        {
          id: "re_456",
          amount: 500,
          currency: "usd",
          metadata: {}
        }
      ])
      create(:refund, amount: 5, payment: payment, transaction_id: "re_123")

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.refunds.pluck(:transaction_id)).to contain_exactly("re_123", "re_456")
    end

    it "adds a log entry for created Solidus refund" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(payment.log_entries.count).to eq(1)
    end

    it "sets created log entry as successful" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 1000,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(
        payment.log_entries.first.parsed_details.success?
      ).to be(true)
    end

    it "uses a meaningful message with the refunded amount in created log entry" do
      SolidusStripe::Seeds.refund_reasons
      payment_intent_id = "pi_123"
      payment = create(:payment, response_code: payment_intent_id, amount: 10, payment_method: payment_method)
      mock_refund_list(payment_intent_id, [
        {
          id: "re_123",
          amount: 500,
          currency: "usd",
          metadata: {}
        }
      ])

      described_class.new(payment_method).call(payment_intent_id)

      expect(
        payment.log_entries.first.parsed_details.message
      ).to include("after Stripe event ($5.00)")
    end
  end
end
