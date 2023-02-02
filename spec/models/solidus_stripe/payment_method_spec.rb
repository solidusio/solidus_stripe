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
    it 'generates a dashboard link' do
      payment_method = build(:stripe_payment_method, preferred_test_mode: false)
      payment_source = build(:stripe_payment_source, stripe_payment_intent_id: 'pi_123')
      payment = build(:payment, source: payment_source)

      expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/payments/pi_123")
    end

    it 'supports test mode' do
      payment_method = build(:stripe_payment_method, preferred_test_mode: true)
      payment_source = build(:stripe_payment_source, stripe_payment_intent_id: 'pi_123')
      payment = build(:payment, source: payment_source)

      expect(payment_method.stripe_dashboard_url(payment)).to eq("https://dashboard.stripe.com/test/payments/pi_123")
    end
  end
end
