# frozen_string_literal: true

require "solidus_stripe_spec_helper"
require "stripe_mock"

RSpec.describe SolidusStripe::CreateSetupIntentForUser do
  subject(:service) do
    described_class.new(
      find_or_create_customer_for_user: SolidusStripe::FindOrCreateCustomerForUser
    )
  end

  before { StripeMock.start }
  after { StripeMock.stop }

  let(:user) { create(:user) }
  let(:payment_method) { create(:solidus_stripe_payment_method) }

  describe '#call' do
    it 'returns the client secret' do
      result = service.call(user: user, payment_method_id: payment_method.id)

      expect(result[:client_secret]).to be_present
    end
  end
end
