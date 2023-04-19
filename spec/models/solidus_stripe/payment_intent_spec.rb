# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentIntent do
  describe "#reload" do
    it "reloads the stripe intent" do
      intent = create(:solidus_stripe_payment_intent)
      allow(Stripe::PaymentIntent).to receive(:retrieve) do
        Stripe::PaymentIntent.construct_from(id: intent.stripe_intent_id)
      end

      expect(intent.stripe_intent.object_id).to eq(intent.stripe_intent.object_id)
      expect(intent.stripe_intent.object_id).not_to eq(intent.reload.stripe_intent.object_id)
    end
  end
end
