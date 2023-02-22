# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Gateway do
  describe '#authorize' do
    it 'uses a manual capture method' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource)
      payment_intent = instance_double(Stripe::PaymentIntent, to_json: '{foo: "pi_123"}')
      allow(Stripe::PaymentIntent).to receive(:create).and_return(payment_intent)

      result = gateway.authorize(123_45, source, currency: 'USD')

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
        capture_method: 'manual',
      )
      expect(result.params['data']).to eq('{foo: "pi_123"}')
    end
  end

  describe '#capture' do
    it 'captures a pre-authorized amount' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource, stripe_payment_intent_id: 'pi_123')
      payment = instance_double(Spree::Payment, source: source)
      payment_intent = instance_double(Stripe::PaymentIntent, to_json: '{foo: "pi_123"}')
      allow(Stripe::PaymentIntent).to receive(:capture).and_return(payment_intent)

      result = gateway.capture(123_45, nil, originator: payment)

      expect(Stripe::PaymentIntent).to have_received(:capture).with('pi_123')
      expect(result.params['data']).to eq('{foo: "pi_123"}')
    end
  end

  describe '#purchase' do
    it 'authorizes and captures in a single operation' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource)
      payment_intent = instance_double(Stripe::PaymentIntent, to_json: '{foo: "pi_123"}')
      allow(Stripe::PaymentIntent).to receive(:create).and_return(payment_intent)

      result = gateway.purchase(123_45, source, currency: 'USD')

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
      )
      expect(result.params['data']).to eq('{foo: "pi_123"}')
    end
  end

  describe '#void' do
    it 'voids a payment that hasn not been captured yet' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource, stripe_payment_intent_id: 'pi_123')
      payment_intent = instance_double(Stripe::PaymentIntent, to_json: '{foo: "pi_123"}')
      allow(Stripe::PaymentIntent).to receive(:cancel).and_return(payment_intent)
      transaction_id = instance_double(String)

      result = gateway.void(transaction_id, source)

      expect(Stripe::PaymentIntent).to have_received(:cancel).with(
        'pi_123'
      )
      expect(result.params['data']).to eq('{foo: "pi_123"}')
    end
  end

  describe '#credit' do
    it 'refunds when provided an originator payment' do
      gateway = build(:stripe_payment_method).gateway
      source = build(:stripe_payment_source, stripe_payment_intent_id: 'pi_123')
      payment = build(:payment, source: source)
      solidus_refund = build(:refund, payment: payment)
      refund = instance_double(Stripe::Refund, to_json: '{foo: "re_123"}')
      allow(Stripe::Refund).to receive(:create).and_return(refund)
      transaction_id = instance_double(String)

      result = gateway.credit(123_45, nil, transaction_id, currency: 'USD', originator: solidus_refund)

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
      )
      expect(result.params['data']).to eq('{foo: "re_123"}')
    end
  end
end
