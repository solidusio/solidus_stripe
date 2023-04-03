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

  describe 'Callbacks' do
    describe 'after_create' do
      it 'creates a webhook endpoint' do
        payment_method = create(:stripe_payment_method)

        expect(payment_method.slug_entry).to be_present
      end
    end
  end

  describe '#intent_id_for_payment' do
    context 'when the payment has a transaction_id' do
      it 'fetches the payment intent id from the response code' do
        payment = build(:payment, response_code: 'pi_123')

        expect(described_class.intent_id_for_payment(payment)).to eq("pi_123")
      end
    end

    context 'when the order has a payment intent' do
      it 'fetches the payment intent id' do
        intent = create(:stripe_payment_intent, stripe_intent_id: 'pi_123')
        payment = build(:payment, response_code: nil, payment_method: intent.payment_method, order: intent.order)

        expect(described_class.intent_id_for_payment(payment)).to eq("pi_123")
      end
    end

    it 'returns nil without a payment' do
      expect(described_class.intent_id_for_payment(nil)).to eq(nil)
    end
  end

  describe '#stripe_dashboard_url' do
    context 'with a payment intent id' do
      it 'generates a dashboard link' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: false)

        expect(payment_method.stripe_dashboard_url('pi_123')).to eq("https://dashboard.stripe.com/payments/pi_123")
      end

      it 'supports test mode' do
        payment_method = build(:stripe_payment_method, preferred_test_mode: true)

        expect(payment_method.stripe_dashboard_url('pi_123')).to eq("https://dashboard.stripe.com/test/payments/pi_123")
      end
    end

    it 'returns nil with anything else' do
      payment_method = build(:stripe_payment_method)

      expect(payment_method.stripe_dashboard_url(Object.new)).to eq(nil)
      expect(payment_method.stripe_dashboard_url('')).to eq(nil)
      expect(payment_method.stripe_dashboard_url(123)).to eq(nil)
    end
  end

  describe '.with_slug' do
    it 'selects by slug' do
      payment_method = create(:stripe_payment_method)

      expect(described_class.with_slug(payment_method.slug)).to eq([payment_method])
      expect(described_class.with_slug('bad-slug')).to eq([])
    end
  end

  describe '.assign_slug' do
    it 'generates a "test" slug for the first payment method in test mode' do
      payment_method = build(:stripe_payment_method)

      payment_method.save!

      expect(payment_method.slug).to eq('test')
    end

    it 'generates a "live" slug for the first payment method in live mode' do
      payment_method = build(:stripe_payment_method, preferred_test_mode: false)

      payment_method.save!

      expect(payment_method.slug).to eq('live')
    end

    it 'generates a random hex string' do
      _existing_payment_method = create(:stripe_payment_method)
      payment_method = create(:stripe_payment_method)

      expect(payment_method.slug).to match(/^[0-9a-f]{32}$/)
    end

    it 'generates a unique slug' do
      slug = SecureRandom.hex(16)

      create(:stripe_slug_entry, slug: slug)
      allow(SecureRandom).to receive(:hex).and_return(slug).and_call_original

      expect(create(:stripe_payment_method).slug).not_to eq(slug)
    end
  end
end
