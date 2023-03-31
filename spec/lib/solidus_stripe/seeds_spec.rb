# frozen-string-literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::Seeds do
  describe ".refund_reasons" do
    it "creates a refund reason" do
      expect do
        described_class.refund_reasons
      end.to change(Spree::RefundReason, :count).from(0).to(1)
    end

    it "uses default name for the refund reason name" do
      described_class.refund_reasons

      expect(Spree::RefundReason.last.name).to eq(described_class::DEFAULT_STRIPE_REFUND_REASON_NAME)
    end

    it "makes the refund reason immutable" do
      described_class.refund_reasons

      expect(Spree::RefundReason.last.mutable).to be(false)
    end

    it "does not duplicate refund reasons" do
      described_class.refund_reasons

      expect do
        described_class.refund_reasons
      end.not_to change(Spree::RefundReason, :count)
    end

    it "does not change the mutable attribute of existing refund reasons" do
      described_class.refund_reasons
      refund_reason = Spree::RefundReason.last
      refund_reason.update_column(:mutable, true)

      described_class.refund_reasons

      expect(refund_reason.reload.mutable).to be(true)
    end
  end
end
