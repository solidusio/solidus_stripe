# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::Customer, type: :model do
  describe ".retrieve_or_create_stripe_customer_id" do
    context 'with an existing customer' do
      it 'returns the customer_id' do
        user = create(:user)
        order = create(:order, user: user)
        customer = create(:stripe_customer, stripe_id: 'cus_123', source: user)

        expect(customer.source).to be_a(Spree::User)
        expect(
          described_class.retrieve_or_create_stripe_customer_id(order: order, payment_method: customer.payment_method)
        ).to eq('cus_123')
      end
    end

    context 'without an existing customer' do
      it 'creates the customer from a user' do
        user = create(:user, email: 'registered@example.com')
        order = create(:order, user: user)
        payment_method = create(:stripe_payment_method)

        stripe_customer = Stripe::Customer.construct_from(id: 'cus_123')
        allow(Stripe::Customer).to receive(:create).with(email: 'registered@example.com').and_return(stripe_customer)

        expect(
          described_class.retrieve_or_create_stripe_customer_id(order: order, payment_method: payment_method)
        ).to eq('cus_123')
      end

      it 'creates the customer from a guest order' do
        payment_method = create(:stripe_payment_method)
        order = create(:order, user: nil, email: 'guest@example.com')

        stripe_customer = Stripe::Customer.construct_from(id: 'cus_123')
        allow(Stripe::Customer).to receive(:create).with(email: 'guest@example.com').and_return(stripe_customer)

        expect(
          described_class.retrieve_or_create_stripe_customer_id(order: order, payment_method: payment_method)
        ).to eq('cus_123')
      end
    end
  end
end
