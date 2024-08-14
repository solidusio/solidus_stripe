# frozen_string_literal: true

require "solidus_stripe_spec_helper"
require "stripe_mock"

RSpec.describe SolidusStripe::FindOrCreateCustomerForUser do
  subject(:service) { described_class.new(user: user, payment_method: payment_method) }

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { create(:user) }
  let(:payment_method) { create(:solidus_stripe_payment_method) }

  describe "#call" do
    context "when the customer already has a stripe_id" do
      let!(:customer) do
        create(:solidus_stripe_customer, payment_method: payment_method, source: user, stripe_id: stripe_id)
      end
      let(:stripe_id) { "cus_123" }

      it "returns the existing customer without creating a new Stripe customer" do
        result = service.call

        expect(result.id).to eq(customer.id)
        expect(result.stripe_id).to eq(customer.stripe_id)
      end
    end

    context "when the customer does not have a stripe_id" do
      let!(:customer) do
        create(:solidus_stripe_customer, payment_method: payment_method, source: user, stripe_id: stripe_id)
      end
      let(:stripe_id) { nil }

      it "creates a new Stripe customer and updates the customer record" do
        result = service.call

        expect(result.id).to eq(customer.id)
        expect(result.stripe_id).to be_present
      end
    end

    context "when the customer does not exist" do
      it "creates new customer and creates a new Stripe customer" do
        result = service.call

        expect(result).to be_a(SolidusStripe::Customer)
        expect(result.stripe_id).to be_present
        expect(result.source).to eq(user)
        expect(result.payment_method).to eq(payment_method)
      end
    end
  end
end
