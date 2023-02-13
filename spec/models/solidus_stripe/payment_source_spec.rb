# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentSource, type: :model do
  it 'has a working factory' do
    expect(create(:stripe_payment_source)).to be_valid
  end
end
