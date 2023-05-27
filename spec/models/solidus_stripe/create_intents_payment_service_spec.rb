# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusStripe::CreateIntentsPaymentService do
  let(:service) { described_class.new(intent_id, stripe, controller) }

  let(:stripe) {
    Spree::PaymentMethod::StripeCreditCard.create!(
      name: "Stripe",
      preferred_secret_key: "sk_test_VCZnDv3GLU15TRvn8i2EsaAN",
      preferred_publishable_key: "pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg",
      preferred_v3_elements: false,
      preferred_v3_intents: true
    )
  }

  let(:order) { create :order, state: :payment, total: 19.99 }

  let(:intent_id) { "pi_123123ABC" }
  let(:controller) { double(current_order: order.reload, params: params, request: spy) }

  let(:params) do
    {
      spree_payment_method_id: stripe.id,
      stripe_payment_intent_id: intent_id,
      form_data: {
        addressLine: ["31 Cotton Rd"],
        city: order.bill_address.city,
        country: order.bill_address.country.iso,
        region: order.bill_address.state.abbr,
        phone: "+188836412312",
        postalCode: "12345",
        recipient: "James Edwards",
      }
    }
  end

  let(:intent) do
    double(params: {
      "id" => intent_id,
      "charges" => {
        "data" => [{
          "billing_details" => {
            "name" => "John Doe"
          },
          "payment_method_details" => {
            "card" => {
              "brand" => "visa",
              "exp_month" => 1,
              "exp_year" => 2022,
              "last4" => "4242"
            },
          }
        }]
      }
    })
  end

  describe '#call' do
    subject { service.call }

    before do
      allow(stripe).to receive(:show_intent) { intent }
      allow_any_instance_of(Spree::CreditCard).to receive(:require_card_numbers?) { false }
      allow_any_instance_of(Spree::PaymentMethod::StripeCreditCard).to receive(:create_profile) { true }
    end

    it { expect(subject).to be true }

    it "creates a new pending payment" do
      expect { subject }.to change { order.payments.count }
      expect(order.payments.last.reload).to be_pending
    end

    it "creates a credit card with the correct information" do
      expect { subject }.to change { Spree::CreditCard.count }
      card = Spree::CreditCard.last

      aggregate_failures do
        expect(card.name).to eq "John Doe"
        expect(card.cc_type).to eq "visa"
        expect(card.month).to eq "1"
        expect(card.year).to eq "2022"
        expect(card.last_digits).to eq "4242"
      end
    end

    context "when for any reason the payment could not be created" do
      before { params[:form_data].delete(:city) }

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when there are previous pending payments" do
      let!(:payment) do
        create(:payment, order: order, amount: order.total).tap do |payment|
          payment.update!(state: :pending)
        end
      end

      before do
        response = ActiveMerchant::Billing::Response.new(true, nil, {}, authorization: payment.response_code)
        allow_any_instance_of(Spree::PaymentMethod::StripeCreditCard).to receive(:void) { response }
      end

      context "when one of them is a Payment Intent" do
        before do
          payment.update!(payment_method: stripe)
          payment.source.update!(payment_method: stripe)
        end

        it "invalidates it" do
          expect { subject }.to change { payment.reload.state }.to 'void'
        end

        context "and the response returns a payment_intent_unexpected_state error" do
          before do
            response_params = { 'error' => { 'code' => 'payment_intent_unexpected_state' } }
            response = double(success?: false, authorization: payment.response_code, params: response_params)
            expect_any_instance_of(Spree::PaymentMethod::StripeCreditCard).to receive(:void) { response }
          end

          it "invalidates it" do
            expect { subject }.to change { payment.reload.state }.to 'void'
          end
        end
      end

      context "when none is a Payment Intent" do
        it "does not invalidate them" do
          expect { subject }.not_to change { payment.reload.state }
        end
      end
    end
  end
end
