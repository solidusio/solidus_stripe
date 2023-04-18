# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Gateway do
  describe '#authorize' do
    it 'confirms the Stripe payment' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123")
      stripe_customer = Stripe::Customer.construct_from(id: 'cus_123')
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order,
        amount: 123.45,
        payment_method: payment_method,
        stripe_payment_method_id: stripe_payment_method.id)
      payment = order.payments.last

      allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
      [:create, :update, :retrieve].each do |method|
        allow(Stripe::PaymentIntent).to receive(method).and_return(stripe_payment_intent)
      end
      allow(Stripe::PaymentIntent).to receive(:confirm).with(stripe_payment_intent.id).and_return(stripe_payment_intent)

      result = gateway.authorize(123_45, payment.source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:update).with(
        stripe_payment_intent.id,
        { payment_method: stripe_payment_method.id }
      )

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
        capture_method: 'manual',
        confirm: false,
        metadata: { solidus_order_number: order.number },
        customer: "cus_123",
        setup_future_usage: nil
      )
      expect(Stripe::PaymentIntent).to have_received(:confirm).with("pi_123")
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
      expect(payment.reload.response_code).to eq("pi_123")
    end

    it 'generates error response on failure' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123")
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order,
        amount: 123.45,
        payment_method: payment_method,
        stripe_payment_method_id: stripe_payment_method.id)
      payment = order.payments.last

      [:create, :update, :retrieve].each do |method|
        allow(Stripe::PaymentIntent).to receive(method).and_return(stripe_payment_intent)
      end
      allow(Stripe::PaymentIntent).to receive(:confirm).with(
        stripe_payment_intent.id
      ).and_raise(Stripe::StripeError.new("auth error"))

      result = gateway.authorize(123_45, payment.source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:confirm).with("pi_123")
      expect(result.success?).to be(false)
      expect(result.message).to eq("auth error")
    end

    it "raises if the given amount doesn't match the order total" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order, amount: 123.45, payment_method: payment_method)

      expect { gateway.authorize(10, :source, originator: order.payments.first ) }.to raise_error(
        /custom amount is not supported/
      )
    end
  end

  describe '#capture' do
    it 'captures a pre-authorized Stripe payment' do
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      gateway = build(:solidus_stripe_payment_method).gateway
      payment = build(:payment, response_code: "pi_123", amount: 123.45)

      allow(Stripe::PaymentIntent).to receive(:capture).and_return(stripe_payment_intent)

      result = gateway.capture(123_45, "pi_123", originator: payment)

      expect(Stripe::PaymentIntent).to have_received(:capture).with('pi_123', { amount: 12_345 })
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
    end

    it "raises if the given amount doesn't match the order total" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(10, :payment_intent_id, originator: order.payments.first ) }.to raise_error(
        /custom amount is not supported/
      )
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(123_45, nil, originator: order.payments.first ) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order, amount: 123.45, payment_method: payment_method)

      expect { gateway.capture(123_45, "invalid", originator: order.payments.first ) }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end

  describe '#void' do
    it 'voids a payment that hasn not been captured yet' do
      gateway = build(:solidus_stripe_payment_method).gateway
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")
      allow(Stripe::PaymentIntent).to receive(:cancel).and_return(stripe_payment_intent)

      result = gateway.void('pi_123')

      expect(Stripe::PaymentIntent).to have_received(:cancel).with('pi_123')
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.void(nil) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.void("invalid") }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end

  describe '#purchase' do
    it 'authorizes and captures in a single operation' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123")
      stripe_customer = Stripe::Customer.construct_from(id: 'cus_123')
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order,
        amount: 123.45,
        payment_method: payment_method,
        stripe_payment_method_id: stripe_payment_method.id)
      payment = order.payments.last

      allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
      [:create, :update, :retrieve].each do |method|
        allow(Stripe::PaymentIntent).to receive(method).and_return(stripe_payment_intent)
      end
      allow(Stripe::PaymentIntent).to receive(:confirm).with(stripe_payment_intent.id).and_return(stripe_payment_intent)

      result = gateway.purchase(123_45, payment.source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:update).with(
        stripe_payment_intent.id,
        { payment_method: stripe_payment_method.id }
      )

      expect(Stripe::PaymentIntent).to have_received(:create).with(
        amount: 123_45,
        currency: 'USD',
        capture_method: 'automatic',
        confirm: false,
        metadata: { solidus_order_number: order.number },
        customer: "cus_123",
        setup_future_usage: nil
      )
      expect(Stripe::PaymentIntent).to have_received(:confirm).with("pi_123")
      expect(result.params).to eq("data" => '{"id":"pi_123"}')
      expect(payment.reload.response_code).to eq("pi_123")
    end

    it 'generates error response on failure' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: "pm_123")
      stripe_payment_intent = Stripe::PaymentIntent.construct_from(id: "pi_123")

      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order,
        amount: 123.45,
        payment_method: payment_method,
        stripe_payment_method_id: stripe_payment_method.id)
      payment = order.payments.last

      [:create, :update, :retrieve].each do |method|
        allow(Stripe::PaymentIntent).to receive(method).and_return(stripe_payment_intent)
      end
      allow(Stripe::PaymentIntent).to receive(:confirm).with(
        stripe_payment_intent.id
      ).and_raise(Stripe::StripeError.new("auth error"))

      result = gateway.purchase(123_45, payment.source, currency: 'USD', originator: order.payments.first)

      expect(Stripe::PaymentIntent).to have_received(:confirm).with("pi_123")
      expect(result.success?).to be(false)
      expect(result.message).to eq("auth error")
    end

    it "raises if the given amount doesn't match the order total" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway
      order = create(:solidus_stripe_order, amount: 123.45, payment_method: payment_method)

      expect { gateway.purchase(10, :source, originator: order.payments.first ) }.to raise_error(
        /custom amount is not supported/
      )
    end
  end

  describe '#credit' do
    it 'refunds when provided an originator payment' do
      gateway = build(:solidus_stripe_payment_method).gateway
      payment = instance_double(Spree::Payment, response_code: 'pi_123', currency: "USD")
      stripe_refund = Stripe::Refund.construct_from(id: "re_123")
      allow(Stripe::Refund).to receive(:create).and_return(stripe_refund)

      result = gateway.credit(123_45, 'pi_123', currency: 'USD', originator: instance_double(
        Spree::Refund,
        payment: payment
      ))

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
        metadata: { solidus_skip_sync: 'true' }
      )
      expect(result.params).to eq("data" => '{"id":"re_123"}')
    end

    it "raises if no payment_intent_id is given" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.credit(:amount, nil) }.to raise_error(
        ArgumentError,
        /missing payment_intent_id/
      )
    end

    it "raises if payment_intent_id is not valid" do
      payment_method = build(:solidus_stripe_payment_method)
      gateway = payment_method.gateway

      expect { gateway.credit(:amount, "invalid") }.to raise_error(
        ArgumentError,
        /payment intent id has the wrong format/
      )
    end
  end
end
