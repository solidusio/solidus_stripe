require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::IntentsController, type: :request do
  describe "GET /after_confirmation" do
    context 'when not provided a payment intent' do
      it 'responds with unprocessable entity' do
        payment_method = create(:stripe_payment_method)
        order = create(:order_ready_to_complete)
        sign_in order.user

        get "/solidus_stripe/#{payment_method.slug}/after_confirmation"

        expect(response.status).to eq(422)
      end
    end

    context 'when the order is not at "confirm"' do
      it 'redirects to the current order step' do
        payment_method = create(:stripe_payment_method)
        order = create(:order)
        sign_in order.user

        get "/solidus_stripe/#{payment_method.slug}/after_confirmation?payment_intent=pi_123"

        expect(response).to redirect_to('/checkout/cart')
      end
    end
  end
end
