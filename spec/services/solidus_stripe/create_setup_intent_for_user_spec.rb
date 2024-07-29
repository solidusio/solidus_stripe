# frozen_string_literal: true

require "solidus_stripe_spec_helper"

RSpec.describe SolidusStripe::CreateSetupIntentForUser do
  subject(:service) do
    described_class.new(
      find_or_create_customer_for_user: SolidusStripe::FindOrCreateCustomerForUser
    )
  end

  let(:user) { create(:user) }
  let(:payment_method) { create(:solidus_stripe_payment_method) }
  let(:gateway) { instance_double(SolidusStripe::Gateway) }
  let(:customer) { instance_double(SolidusStripe::Customer, stripe_id: 'cus_123') }
  let(:find_or_create_customer_for_user_instance) { instance_double(SolidusStripe::FindOrCreateCustomerForUser) }

  before do
    allow(payment_method).to receive(:gateway).and_return(gateway)

    allow(SolidusStripe::FindOrCreateCustomerForUser).to receive(:new)
      .with(user: user, payment_method: payment_method)
      .and_return(find_or_create_customer_for_user_instance)
    allow(find_or_create_customer_for_user_instance).to receive(:call).and_return(customer)

    allow(gateway).to receive(:request).and_yield
    allow(::Stripe::SetupIntent).to receive(:create).with(
      { customer: CGI.escape('cus_123') }
    ).and_return({ 'client_secret' => 'example_client_secret' })
  end

  describe '#call' do
    it 'returns the client secret' do
      result = service.call(user: user, payment_method_id: payment_method.id)

      expect(result).to eq({ client_secret: 'example_client_secret' })
      expect(
        SolidusStripe::FindOrCreateCustomerForUser
      ).to have_received(:new).with(user: user, payment_method: payment_method)
      expect(find_or_create_customer_for_user_instance).to have_received(:call)
      expect(::Stripe::SetupIntent).to have_received(:create).with({ customer: CGI.escape('cus_123') })
    end
  end
end
