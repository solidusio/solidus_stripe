# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusStripe::PrepareOptionsForIntentService do
  let(:order) { create(:order_with_line_items) }
  let(:payment_method) {
    Spree::PaymentMethod::StripeCreditCard.create(
      name: 'Stripe',
      preferred_secret_key: 'secret',
      preferred_publishable_key: 'published',
      preferred_stripe_connect: stripe_connect,
      preferred_connected_account: 'connect_account',
      preferred_connected_mode: connected_mode
    )
  }
  let(:connected_mode) { 'direct_charge' }
  let(:service) { described_class.new(order, payment_method) }
  let(:intent_options) { service.call }

  context 'without stripe connect' do
    let(:stripe_connect) { false }

    it 'dont has any connect attributes' do
      expect(intent_options[:application_fee]).to be_nil
    end
  end

  context 'with stripe connect' do
    let(:stripe_connect) { true }

    before do
      SolidusStripe.configure do |app|
        app.application_fee = 5
      end
    end

    it 'has application_fee option' do
      expect(intent_options[:application_fee_amount]).to eq(5)
    end

    it 'has stripe_account option' do
      expect(intent_options[:stripe_account]).to eq('connect_account')
    end

    context 'with destination_charge mode' do
      let(:connected_mode) { 'destination_charge' }

      it 'has transfer_destionation option' do
        expect(intent_options[:transfer_data][:destination]).to eq('connect_account')
      end

      it 'doesnt have stripe_account option' do
        expect(intent_options[:stripe_account]).to be_nil
      end
    end
  end
end
