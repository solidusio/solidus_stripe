# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentSource, type: :model do
  it 'has a working factory' do
    expect(create(:stripe_payment_source)).to be_valid
  end

  describe '#stripe_payment_method' do
    it 'retrieves the Stripe::PaymentMethod object if the stripe_payment_method id is present' do
      stripe_payment_method = Stripe::PaymentMethod.construct_from(id: 'pm_123')
      source = create(:stripe_payment_source, stripe_payment_method_id: 'pm_123')
      allow(Stripe::PaymentMethod).to receive(:retrieve).with('pm_123').and_return(stripe_payment_method)

      expect(source.stripe_payment_method).to eq(stripe_payment_method)
    end

    it 'returns nil if the stripe_payment_method id is missing' do
      source = create(:stripe_payment_source, stripe_payment_method_id: nil)

      expect(source.stripe_payment_method).to be_nil
    end
  end
end
