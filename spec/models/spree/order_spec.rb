# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Order, type: :model do
  describe 'payment intent cleanup on destruction' do
    let(:order) { create(:order) }
    let(:payment_method) { create(:solidus_stripe_payment_method) }

    context 'when order has associated payment intents' do
      let!(:payment_intent) do
        SolidusStripe::PaymentIntent.create!(
          order: order,
          payment_method: payment_method,
          stripe_intent_id: 'pi_test_123'
        )
      end

      it 'destroys associated payment intents when order is destroyed' do
        expect { order.destroy }.to change { SolidusStripe::PaymentIntent.count }.by(-1)
      end

      it 'does not raise foreign key constraint error' do
        expect { order.destroy }.not_to raise_error
      end

      it 'successfully removes the order from database' do
        order.destroy
        expect(Spree::Order.find_by(id: order.id)).to be_nil
      end
    end

    context 'during order merging' do
      let(:user) { create(:user) }
      let(:current_order) { create(:order, user: user) }
      let(:abandoned_order) { create(:order, user: user) }

      before do
        # Create a payment intent for the abandoned order
        SolidusStripe::PaymentIntent.create!(
          order: abandoned_order,
          payment_method: payment_method,
          stripe_intent_id: 'pi_test_merge'
        )
      end

      it 'successfully merges orders without foreign key errors' do
        expect {
          current_order.merge!(abandoned_order, user)
        }.not_to raise_error
      end

      it 'cleans up payment intents from merged order' do
        initial_count = SolidusStripe::PaymentIntent.count
        current_order.merge!(abandoned_order, user)
        
        # The abandoned order and its payment intents should be gone
        expect(SolidusStripe::PaymentIntent.count).to eq(initial_count - 1)
        expect(Spree::Order.find_by(id: abandoned_order.id)).to be_nil
      end
    end

    context 'real-world login scenario' do
      let(:user) { create(:user) }

      it 'handles abandoned cart with payment intent during login' do
        # Simulate abandoned cart with payment intent
        abandoned_cart = create(:order, state: 'payment', user: user)
        SolidusStripe::PaymentIntent.create!(
          order: abandoned_cart,
          payment_method: payment_method,
          stripe_intent_id: 'pi_abandoned'
        )

        # Simulate new guest cart
        guest_cart = create(:order, state: 'cart')

        # This simulates what happens in set_current_order after login
        expect {
          guest_cart.merge!(abandoned_cart, user)
        }.not_to raise_error

        expect(Spree::Order.find_by(id: abandoned_cart.id)).to be_nil
        expect(SolidusStripe::PaymentIntent.where(order_id: abandoned_cart.id)).to be_empty
      end
    end
  end
end