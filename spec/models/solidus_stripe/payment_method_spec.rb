# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentMethod do
  it 'has a working factory' do
    expect(create(:stripe_payment_method)).to be_valid
  end

  it "doesn't allow available_to_admin" do
    record = described_class.new(available_to_admin: true)

    record.valid?

    expect(
      record.errors.added?(:available_to_admin, :inclusion, value: true)
    ).to be(true)
  end

  describe '#stripe_dashboard_url' do
    context 'when the payment has a transaction_id' do
      it 'generates a dashboard link' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: false)
        payment = build(:payment, response_code: 'pi_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/payments/pi_123")
      end

      it 'supports test mode' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: true)
        payment = build(:payment, response_code: 'pi_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/test/payments/pi_123")
      end
    end

    context 'when the order has a payment intent' do
      it 'generates a dashboard link' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: false)
        payment = build(:payment, response_code: nil)
        _intent = SolidusStripe::PaymentIntent.create(order: payment.order, stripe_payment_intent_id: 'pi_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/payments/pi_123")
      end

      it 'supports test mode' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: true)
        payment = build(:payment, response_code: nil)
        _intent = SolidusStripe::PaymentIntent.create(order: payment.order, stripe_payment_intent_id: 'pi_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/test/payments/pi_123")
      end
    end

    context 'when the order has a setup intent' do
      it 'generates a dashboard link' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: false)
        payment = build(:payment, response_code: nil)
        _intent = SolidusStripe::SetupIntent.create(order: payment.order, stripe_setup_intent_id: 'seti_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/setup_intents/seti_123")
      end

      it 'supports test mode' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: true)
        payment = build(:payment, response_code: nil)
        _intent = SolidusStripe::SetupIntent.create(order: payment.order, stripe_setup_intent_id: 'seti_123')

        expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/test/setup_intents/seti_123")
      end
    end
  end
end
