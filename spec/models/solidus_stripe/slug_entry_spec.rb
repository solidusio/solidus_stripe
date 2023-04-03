# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::SlugEntry do
  describe '.payment_method' do
    it 'finds the payment method associated with the given slug' do
      payment_method = create(:stripe_payment_method)
      described_class.create!(payment_method: payment_method, slug: 'foo')

      expect(described_class.payment_method('foo')).to eq(payment_method)
    end

    it 'raises an error if no payment method is found' do
      expect { described_class.payment_method('invalid') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
