# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::PaymentIntentsController, type: :request do
  describe "POST /create" do
    it "returns http success" do
      store = create(:store, default: true)
      order = create(:order_with_totals, store: store, user: nil, line_items_price: 123.45)
      payment_method = create(:stripe_payment_method)
      payment_intent = Stripe::PaymentIntent.construct_from(
        id: 'pi_test_1234567890',
        client_secret: 'cs_test_1234567890',
      )

      allow(Stripe::PaymentIntent).to receive(:create).with({
        amount: 123_45,
        currency: 'USD',
        capture_method: 'manual',
      }).and_return(payment_intent, instance_double(Stripe::StripeResponse))
      allow_any_instance_of(described_class).to receive_message_chain(
        :cookies,
        :signed,
      ).and_return(guest_token: order.guest_token)

      post "/solidus_stripe/payment_intents?payment_method_id=#{payment_method.id}"

      expect(response).to have_http_status(:success)
      expect(Stripe::PaymentIntent).to have_received(:create)
      expect(SolidusStripe::PaymentSource.where(
        stripe_payment_intent_id: 'pi_test_1234567890',
        payment_method: payment_method,
      ).count).to eq(1)
      expect(JSON.parse(response.body)).to eq(
        'client_secret' => 'cs_test_1234567890'
      )
    end
  end
end
