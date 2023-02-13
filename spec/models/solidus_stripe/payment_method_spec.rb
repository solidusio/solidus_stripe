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
end
