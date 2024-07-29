# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::CreatePaymentIntentForOrder, type: :service do
  subject(:service) do
    described_class.new(
      order_id: order.id,
      payment_method_id: payment_method.id,
      stripe_payment_method_id: 'pm_123'
    )
  end

  let(:user) { Spree::User.create!(email: 'test@example.com', password: 'password') }
  let(:payment_method) { SolidusStripe::PaymentMethod.create!(name: 'Stripe', type: 'SolidusStripe::PaymentMethod') }
  let(:payment_source) {
    SolidusStripe::PaymentSource.create!(payment_method: payment_method, stripe_payment_method_id: 'pm_123')
  }
  let(:order) do
    order = create(:order_with_line_items, email: nil, user: nil)
    allow(order.payments).to receive(:create!).and_return(order.payments.last)
    order
  end
  let(:stripe_intent) { instance_double('StripeIntent', client_secret: 'secret_123') }

  before do
    allow(SolidusStripe::PaymentSource).to receive(:find_or_create_by!).with(
      payment_method_id: payment_method.id, stripe_payment_method_id: 'pm_123'
    ).and_return(payment_source)
    allow(SolidusStripe::PaymentIntent).to receive(:prepare_for_payment)
      .and_return(instance_double(SolidusStripe::PaymentIntent, stripe_intent: stripe_intent))
  end

  describe '#call' do
    it 'creates a new payment intent and returns the client secret' do
      result = service.call
      expect(result[:client_secret]).to eq('secret_123')
    end
  end
end
