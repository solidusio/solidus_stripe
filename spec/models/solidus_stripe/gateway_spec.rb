# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Gateway do
  describe '#capture' do
    it 'captures a pre-authorized Stripe payment' do
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      gateway = build(:stripe_payment_method).gateway
      payment = build(:payment, response_code: "pi_123", amount: 123.45)

      allow(Stripe::PaymentIntent).to receive(:capture).and_return(stripe_payment_intent)

      result = gateway.capture(123_45, "pi_123", originator: payment)

      expect(Stripe::PaymentIntent).to have_received(:capture).with('pi_123')
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
    end

    it "raises if the given amount doesn't match the order total" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:order_with_stripe_payment, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(10, :payment_intent_id, originator: order.payments.first ) }.to raise_error(
        /custom amount is not supported/
      )
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:order_with_stripe_payment, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(123_45, nil, originator: order.payments.first ) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:order_with_stripe_payment, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(123_45, "invalid", originator: order.payments.first ) }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end

  describe '#void' do
    it 'voids a payment that hasn not been captured yet' do
      gateway = build(:stripe_payment_method).gateway
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      allow(Stripe::PaymentIntent).to receive(:cancel).and_return(stripe_payment_intent)

      result = gateway.void('pi_123')

      expect(Stripe::PaymentIntent).to have_received(:cancel).with('pi_123')
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.void(nil) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.void("invalid") }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end

  describe '#credit' do
    it 'refunds when provided an originator payment' do
      gateway = build(:stripe_payment_method).gateway
      payment = instance_double(Spree::Payment, response_code: 'pi_123', currency: "USD")
      refund = instance_double(Stripe::Refund, to_json: '{foo: "re_123"}')
      allow(Stripe::Refund).to receive(:create).and_return(refund)

      result = gateway.credit(123_45, 'pi_123', currency: 'USD', originator: instance_double(
        Spree::Refund,
        payment: payment
      ))

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
      )
      expect(result.params).to eq("data" => '{foo: "re_123"}')
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.credit(:amount, nil) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.credit(:amount, "invalid") }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end
end
