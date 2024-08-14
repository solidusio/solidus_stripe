# frozen_string_literal: true

require 'solidus_stripe_spec_helper'
require 'stripe_mock'

RSpec.describe Spree::SolidusStripe::Api::IntentsController, type: :request do
  include SolidusStripe::BackendTestHelper

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:stripe_test_helper) { StripeMock.create_test_helper }
  let(:current_api_user) do
    user = create(:user)
    user.generate_spree_api_key!
    user
  end
  let(:payment_method) { create(:solidus_stripe_payment_method) }

  describe '#create_setup_intent' do
    context 'when the user is logged in' do
      before do
        allow(Spree.user_class).to receive(:find_by).with(hash_including(:spree_api_key)) { current_api_user }
      end

      it 'creates a setup intent and returns a client secret' do
        post spree.solidus_stripe_api_create_setup_intent_path, params: { payment_method_id: payment_method.id }

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to be_present
      end
    end

    context 'when the user is not logged in' do
      it 'returns unauthorized status' do
        post spree.solidus_stripe_api_create_setup_intent_path,
          params: { payment_method_id: payment_method.id }

        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create_payment_intent' do
    let(:stripe_payment_method) { create_stripe_payment_method('4242424242424242') }

    context 'when the user is logged in' do
      let(:order) { create(:order, total: 500, user: current_api_user) }

      stub_authorization!

      it 'creates a payment intent and returns a client secret' do
        allow(Spree.user_class).to receive(:find_by).with(hash_including(:spree_api_key)) { current_api_user }
        allow(current_api_user).to receive(:last_incomplete_order).and_return(order)

        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { payment_method_id: payment_method.id, stripe_payment_method_id: stripe_payment_method.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to be_present
      end
    end

    context 'when the user is not logged in and provides a guest token' do
      let(:guest_order) { create(:order, total: 5000, guest_token: 'guest_token1234') }

      it 'creates a payment intent for a guest order and returns a client secret' do
        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { guest_token: guest_order.guest_token, payment_method_id: payment_method.id,
                    stripe_payment_method_id: stripe_payment_method.id }

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to be_present
      end
    end

    context 'when the order is not found' do
      it 'returns a not found status' do
        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { guest_token: 'invalid_token', payment_method_id: payment_method.id,
                    stripe_payment_method_id: 'fake_pm_123' }

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('Order not found')
      end
    end
  end
end
