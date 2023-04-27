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

  describe '.usable?' do
    context 'when the Stripe intent is usable' do
      it 'returns true' do
        payment_intent = create(:solidus_stripe_payment_intent, order: create(:order_with_line_items))
        status = 'requires_payment_method'
        stripe_intent = Stripe::PaymentIntent.construct_from(
          id: payment_intent.stripe_intent_id,
          amount: payment_intent.stripe_order_amount,
          status: status
        )

        allow(payment_intent).to receive(:stripe_intent).and_return(stripe_intent)

        expect(payment_intent).to be_usable
      end
    end

    context 'when the Stripe intent ID is nil' do
      it 'returns false' do
        payment_intent = create(:solidus_stripe_payment_intent,
          order: create(:order_with_line_items),
          stripe_intent_id: nil)

        expect(payment_intent).not_to be_usable
      end
    end

    context 'when the Stripe intent status is not "requires_payment_method"' do
      it 'returns false' do
        payment_intent = create(:solidus_stripe_payment_intent, order: create(:order_with_line_items))
        status = 'requires_action'
        stripe_intent = Stripe::PaymentIntent.construct_from(
          id: payment_intent.stripe_intent_id,
          amount: payment_intent.stripe_order_amount,
          status: status
        )

        allow(payment_intent).to receive(:stripe_intent).and_return(stripe_intent)

        expect(payment_intent).not_to be_usable
      end
    end

    context 'when the Stripe intent amount is different from the order amount' do
      it 'returns false' do
        payment_intent = create(:solidus_stripe_payment_intent, order: create(:order_with_line_items))
        status = 'requires_payment_method'
        amount = payment_intent.stripe_order_amount + 1
        stripe_intent = Stripe::PaymentIntent.construct_from(
          id: payment_intent.stripe_intent_id,
          amount: amount,
          status: status
        )

        allow(payment_intent).to receive(:stripe_intent).and_return(stripe_intent)

        expect(payment_intent).not_to be_usable
      end
    end
  end
end
