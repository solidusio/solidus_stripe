# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::FindOrCreateCustomerForUser do
  subject(:service) { described_class.new(user: user, payment_method: payment_method) }

  let(:user) { create(:user) }
  let(:payment_method) { instance_double(SolidusStripe::PaymentMethod) }
  let(:customer) { instance_double(SolidusStripe::Customer, stripe_id: stripe_id) }

  before do
    allow(SolidusStripe::Customer).to receive(:find_or_create_by!).with(source: user,
      payment_method: payment_method).and_return(customer)
    allow(customer).to receive(:create_stripe_customer).and_return(customer)
    allow(customer).to receive(:update!)
    allow(customer).to receive(:id).and_return("cus_123")
  end

  describe "#call" do
    context "when the customer already has a stripe_id" do
      let(:stripe_id) { "cus_123" }

      it "returns the existing customer without creating a new Stripe customer" do
        result = service.call

        expect(result).to eq(customer)
        expect(SolidusStripe::Customer).to have_received(:find_or_create_by!).with(source: user,
          payment_method: payment_method)
        expect(customer).not_to have_received(:create_stripe_customer)
        expect(customer).not_to have_received(:update!)
      end
    end

    context "when the customer does not have a stripe_id" do
      let(:stripe_id) { nil }

      it "creates a new Stripe customer and updates the customer record" do
        result = service.call

        expect(result).to eq(customer)
        expect(SolidusStripe::Customer).to have_received(:find_or_create_by!).with(source: user,
          payment_method: payment_method)
        expect(customer).to have_received(:create_stripe_customer)
        expect(customer).to have_received(:update!).with(stripe_id: "cus_123")
      end

      it "creates the Stripe customer with the correct parameters" do
        service.call

        expect(customer).to have_received(:create_stripe_customer)
      end

      it "updates the customer with the Stripe customer ID" do
        service.call

        expect(customer).to have_received(:update!).with(stripe_id: "cus_123")
      end
    end
  end
end
