# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::Configuration do
  describe "#initialize" do
    it "defaults webhook events to empty" do
      expect(described_class.new.webhook_events).to eq([])
    end

    it "defaults webhook signature tolerance to stripe's default" do
      expect(described_class.new.webhook_signature_tolerance).to eq(Stripe::Webhook::DEFAULT_TOLERANCE)
    end

    it "defaults refund reason name to the one in seeds" do
      expect(
        described_class.new.refund_reason_name
      ).to eq(SolidusStripe::Seeds::DEFAULT_STRIPE_REFUND_REASON_NAME)
    end
  end
end
