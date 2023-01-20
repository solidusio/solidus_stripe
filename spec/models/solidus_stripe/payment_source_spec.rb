# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentSource, type: :model do
  describe '#stripe_payment_intent_id' do
    it 'is aliased as gateway_payment_profile_id' do
      payment_source = described_class.new

      payment_source.gateway_payment_profile_id = "pi_123"
      expect(payment_source.stripe_payment_intent_id).to eq("pi_123")

      payment_source.stripe_payment_intent_id = "pi_456"
      expect(payment_source.gateway_payment_profile_id).to eq("pi_456")
    end
  end

  describe '#paynment_intent' do
    it 'fetches the payment intent object from stripe' do
      payment_method = build(:stripe_payment_method)
      payment_source = described_class.new(stripe_payment_intent_id: 'pi_123', payment_method: payment_method)
      payment_intent = instance_double(Stripe::PaymentIntent)
      allow(Stripe::PaymentIntent).to receive(:retrieve).with('pi_123').and_return(payment_intent)

      expect(payment_source.payment_intent).to eq(payment_intent)
    end
  end

  describe '#stripe_dashboard_url' do
    it 'generates a dashboard link' do
      payment_method = build(:stripe_payment_method, preferred_test_mode: false)
      payment_source = described_class.new(stripe_payment_intent_id: 'pi_123', payment_method: payment_method)

      expect(payment_source.stripe_dashboard_url).to eq("https://dashboard.stripe.com/payments/pi_123")
    end

    it 'supports test mode' do
      payment_method = build(:stripe_payment_method, preferred_test_mode: true)
      payment_source = described_class.new(stripe_payment_intent_id: 'pi_123', payment_method: payment_method)

      expect(payment_source.stripe_dashboard_url).to eq("https://dashboard.stripe.com/test/payments/pi_123")
    end
  end
end
