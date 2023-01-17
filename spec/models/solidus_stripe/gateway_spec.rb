# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

# rubocop:disable Style/NumericLiterals
RSpec.describe SolidusStripe::Gateway do
  describe SolidusStripe::Gateway::MoneyToStripeAmountConverter do
    describe '.to_stripe_amount' do
      it 'converts to the fractional expected by stripe' do
        (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
          expect([currency, described_class.to_stripe_amount(12345, currency).to_i]).to eq([currency, 12345])
        end

        %w[USD EUR ILS MXN TWD].each do |currency| # 2 decimals on both sides, default case
          expect([currency, described_class.to_stripe_amount(123_45, currency).to_i]).to eq([currency, 123_45])
        end

        described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
          expect([currency, described_class.to_stripe_amount(12_345, currency).to_i]).to eq([currency, 12_345])
        end

        # Special cases
        expect(['MGA', described_class.to_stripe_amount(255, 'MGA').to_i]).to eq(['MGA', 51])
        expect(['HUF', described_class.to_stripe_amount(1_2345, 'HUF').to_i]).to eq(['HUF', 12_345_00])
        expect(['UGX', described_class.to_stripe_amount(12_3450_00, 'UGX').to_i]).to eq(['UGX', 123_450_00])
        expect(['TWD', described_class.to_stripe_amount(1_2345_00, 'TWD').to_i]).to eq(['TWD', 12_345_00])
      end
    end
  end

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
      expect(result.params['stripe_payment_intent']).to eq('{foo: "pi_123"}')
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
      expect(result.params['stripe_payment_intent']).to eq('{foo: "pi_123"}')
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
      expect(result.params['stripe_payment_intent']).to eq('{foo: "pi_123"}')
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
      expect(result.params['stripe_payment_intent']).to eq('{foo: "pi_123"}')
    end
  end

  describe '#credit' do
    it 'refunds when provided a source' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource, stripe_payment_intent_id: 'pi_123')
      refund = instance_double(Stripe::Refund, to_json: '{foo: "re_123"}')
      allow(Stripe::Refund).to receive(:create).and_return(refund)
      transaction_id = instance_double(String)

      result = gateway.credit(123_45, source, transaction_id, currency: 'USD')

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
      )
      expect(result.params['stripe_refund']).to eq('{foo: "re_123"}')
    end

    it 'refunds when provided an originator payment' do
      gateway = build(:stripe_payment_method).gateway
      source = instance_double(SolidusStripe::PaymentSource, stripe_payment_intent_id: 'pi_123')
      payment = instance_double(Spree::Payment, source: source)
      refund = instance_double(Stripe::Refund, to_json: '{foo: "re_123"}')
      allow(Stripe::Refund).to receive(:create).and_return(refund)
      transaction_id = instance_double(String)

      result = gateway.credit(123_45, nil, transaction_id, currency: 'USD', originator: payment)

      expect(Stripe::Refund).to have_received(:create).with(
        payment_intent: 'pi_123',
        amount: 123_45,
      )
      expect(result.params['stripe_refund']).to eq('{foo: "re_123"}')
    end
  end
end
# rubocop:enable Style/NumericLiterals
