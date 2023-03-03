# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Gateway do
  describe '#authorize' do
    it 'uses a manual capture method' do
      payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123", customer: "cus_123")
      payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource, stripe_payment_method: payment_method)
      allow(Stripe::PaymentIntent).to receive(:create).and_return(payment_intent)

      result = gateway.authorize(123_45, source, currency: 'USD')

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
        capture_method: 'manual',
        confirm: true,
        customer: 'cus_123',
        payment_method: 'pm_123',
      )
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
    end
  end

  describe '#capture' do
    it 'captures a pre-authorized amount' do
      gateway = build(:stripe_payment_method).gateway
      payment = build(:payment, response_code: "pi_123", amount: 123.45)
      intent = Stripe::PaymentIntent.construct_from(id: "pi_123", object: "payment_intent")
      allow(Stripe::PaymentIntent).to receive(:capture).and_return(intent)

      result = gateway.capture(123_45, "pi_123", originator: payment)

      expect(Stripe::PaymentIntent).to have_received(:capture).with('pi_123')
      expect(result.params).to eq("data" => '{"id":"pi_123","object":"payment_intent"}')
    end
  end

  describe '#purchase' do
    it 'authorizes and captures in a single operation' do
      gateway = build(:stripe_payment_method).gateway
      intent = Stripe::PaymentIntent.construct_from(id: "pi_123", object: "payment_intent")
      allow(Stripe::PaymentIntent).to receive(:create).and_return(intent)

      result = gateway.purchase(123_45, nil, currency: 'USD')

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
      )
      expect(result.params).to eq("data" => '{"id":"pi_123","object":"payment_intent"}')
    end
  end

  describe '#void' do
    it 'voids a payment that hasn not been captured yet' do
      gateway = build(:stripe_payment_method).gateway
      intent = Stripe::PaymentIntent.construct_from(id: "pi_123", object: "payment_intent")
      allow(Stripe::PaymentIntent).to receive(:cancel).and_return(intent)

      result = gateway.void('pi_123', nil)

      expect(Stripe::PaymentIntent).to have_received(:cancel).with('pi_123')
      expect(result.params).to eq("data" => '{"id":"pi_123","object":"payment_intent"}')
    end
  end

  describe '#credit' do
    it 'refunds when provided an originator payment' do
      gateway = build(:stripe_payment_method).gateway
      payment = instance_double(Spree::Payment, response_code: 'pi_123', currency: "USD")
      refund = instance_double(Stripe::Refund, to_json: '{foo: "re_123"}')
      allow(Stripe::Refund).to receive(:create).and_return(refund)

      result = gateway.credit(123_45, nil, 'pi_123', currency: 'USD', originator: instance_double(
        Spree::Refund,
        payment: payment
      ))

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
      )
      expect(result.params).to eq("data" => '{foo: "re_123"}')
    end
  end
end
