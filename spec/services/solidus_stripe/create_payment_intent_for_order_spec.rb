# frozen_string_literal: true

require "solidus_stripe_spec_helper"
require "stripe_mock"

RSpec.describe SolidusStripe::CreatePaymentIntentForOrder, type: :service do
  include SolidusStripe::BackendTestHelper

  subject(:service) do
    described_class.new(
      order_id: order.id,
      payment_method_id: payment_method.id,
      stripe_payment_method_id: stripe_payment_method.id
    )
  end

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:stripe_payment_method) { create_stripe_payment_method('4242424242424242') }
  let(:payment_method) { create(:solidus_stripe_payment_method, name: 'Stripe', type: 'SolidusStripe::PaymentMethod') }
  let(:order) { create(:order, total: 500) }

  describe '#call' do
    it 'creates a new payment intent and returns the client secret' do
      result = service.call
      expect(result[:client_secret]).to be_present
    end
  end
end
