# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Gateway do
  describe '#authorize' do
    it 'uses a manual capture method' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123", customer: "cus_123")
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      payment_method = build(:stripe_payment_method)
      source = build(:stripe_payment_source, stripe_payment_method_id: "pi_123", payment_method: payment_method)
      gateway = payment_method.gateway
      order = create(:order,
        line_items: [build(:line_item, price: 123.45)],
        payments: [create(:payment, amount: 123.45, payment_method: payment_method)], &:recalculate)

      allow(source).to receive(:stripe_payment_method).and_return(stripe_payment_method)
      allow(Stripe::PaymentIntent).to receive(:create).and_return(stripe_payment_intent)

      result = gateway.authorize(123_45, source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
        capture_method: 'manual',
        confirm: true,
        metadata: { solidus_order_number: order.number },
        customer: "cus_123",
        payment_method: "pm_123",
        setup_future_usage: nil
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
      intent = Stripe::PaymentIntent.construct_from(id: "pi_123", object: "payment_intent")

      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway
      source = build(:stripe_payment_source, stripe_payment_method_id: "pi_123", payment_method: payment_method)
      order = create(:order,
        line_items: [build(:line_item, price: 123.45)],
        payments: [create(:payment, amount: 123.45, payment_method: payment_method)], &:recalculate)

      allow(Stripe::PaymentIntent).to receive(:create).and_return(intent)

      result = gateway.purchase(123_45, source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:create).with(a_hash_including(
        amount: 123_45,
        currency: 'USD'
      ))

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
