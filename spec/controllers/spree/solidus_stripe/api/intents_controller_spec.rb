require 'solidus_stripe_spec_helper'

RSpec.describe Spree::SolidusStripe::Api::IntentsController, type: :request do
  let(:current_api_user) do
    user = create(:user)
    user.generate_spree_api_key!
    user
  end
  let(:order) { create(:order_ready_to_complete, user: current_api_user) }
  let(:guest_order) { create(:order, guest_token: 'guest_token1234') }

  let(:setup_intent_service) { instance_double(SolidusStripe::CreateSetupIntentForUser) }
  let(:payment_intent_service) { instance_double(SolidusStripe::CreatePaymentIntentForOrder) }

  before do
    intent_result = {
      client_secret: 'fake_client_secret',
      stripe_payment_method_id: 'fake_pm_123'
    }

    allow(SolidusStripe::CreateSetupIntentForUser).to receive(:new).and_return(setup_intent_service)
    allow(setup_intent_service).to receive(:call).and_return(intent_result)

    allow(SolidusStripe::CreatePaymentIntentForOrder).to receive(:new).and_return(payment_intent_service)
    allow(payment_intent_service).to receive(:call).and_return(intent_result)
  end

  describe '#create_setup_intent' do
    context 'when the user is logged in' do
      subject(:request) do
        post spree.solidus_stripe_api_create_setup_intent_path,
          params: { payment_method_id: 'pm_123' }
      end

      before do
        allow(Spree.user_class).to receive(:find_by).with(hash_including(:spree_api_key)) { current_api_user }
      end

      it 'creates a setup intent' do
        request

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to eq('fake_client_secret')
        expect(SolidusStripe::CreateSetupIntentForUser).to have_received(:new)
        expect(setup_intent_service).to have_received(:call).with(
          user: current_api_user,
          payment_method_id: 'pm_123'
        )
      end
    end

    context 'when the user is not logged in' do
      subject(:request) do
        post spree.solidus_stripe_api_create_setup_intent_path, params: { payment_method_id: 'pm_123' }
      end

      it 'cannot create a setup intent' do
        request

        expect(response.status).to eq(401)
      end
    end
  end

  describe '#create_payment_intent' do
    context 'when the user is logged in' do
      subject(:request) do
        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { payment_method_id: 'pm_123', stripe_payment_method_id: 'fake_pm_123' }
      end

      stub_authorization!

      it 'creates a payment intent' do
        allow(Spree.user_class).to receive(:find_by).with(hash_including(:spree_api_key)) { current_api_user }
        allow(current_api_user).to receive(:last_incomplete_spree_order).and_return(order)

        request

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to eq('fake_client_secret')
        expect(SolidusStripe::CreatePaymentIntentForOrder).to have_received(:new).with(
          order_id: order.id,
          payment_method_id: 'pm_123',
          stripe_payment_method_id: 'fake_pm_123'
        )
        expect(payment_intent_service).to have_received(:call)
      end
    end

    context 'when the user is not logged in' do
      subject(:request) do
        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { guest_token: 'guest_token1234', payment_method_id: 'pm_123',
                    stripe_payment_method_id: 'fake_pm_123' }
      end

      it 'creates a payment intent for a guest order' do
        allow(Spree::Order).to receive(:find_by!).with(guest_token: 'guest_token1234').and_return(guest_order)

        request

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['client_secret']).to eq('fake_client_secret')
        expect(SolidusStripe::CreatePaymentIntentForOrder).to have_received(:new).with(
          order_id: guest_order.id,
          payment_method_id: 'pm_123',
          stripe_payment_method_id: 'fake_pm_123'
        )
        expect(payment_intent_service).to have_received(:call)
      end
    end

    context 'when the order is not found' do
      subject(:request) do
        post spree.solidus_stripe_api_create_payment_intent_path,
          params: { guest_token: 'invalid_token', payment_method_id: 'pm_123',
                    stripe_payment_method_id: 'fake_pm_123' }
      end

      it 'returns a not found status' do
        allow(Spree::Order).to receive(:find_by!)
          .with(guest_token: 'invalid_token').and_raise(ActiveRecord::RecordNotFound)

        request

        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('The resource you were looking for could not be found.')
      end
    end
  end
end
