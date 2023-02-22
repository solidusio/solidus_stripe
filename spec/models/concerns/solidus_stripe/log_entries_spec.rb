# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe SolidusStripe::LogEntries do
  describe '#payment_log' do
    it 'creates a new Spree::LogEntry associated to the payment' do
      payment = create(:payment)

      expect {
        described_class.payment_log(
          payment,
          message: "Hi there!",
          success: true,
        )
      }.to change(Spree::LogEntry, :count).by(1)

      details = payment.log_entries.last.parsed_details

      expect(details).to respond_to(:success?)
      expect(details).to respond_to(:message)
      expect(details.message).to eq("Hi there!")
      expect(details.success?).to eq(true)
    end
  end

  describe '#build_payment_log' do
    it 'creates an object suitable for serialization in a Spree::LogEntry' do
      details = described_class.build_payment_log(
        message: "Hi there!",
        success: true,
      )

      expect(details).to respond_to(:success?)
      expect(details).to respond_to(:message)
      expect(details.message).to eq("Hi there!")
      expect(details.success?).to eq(true)
    end

    it 'accepts data and a response_code' do
      details = described_class.build_payment_log(
        message: "Hi there!",
        success: true,
        response_code: 'foo_123',
        data: { foo: :Bar },
      )

      expect(details.message).to eq("Hi there!")
      expect(details.success?).to eq(true)
      expect(details.authorization).to eq('foo_123')
      expect(details.params).to eq("data" => '{"foo":"Bar"}')
    end
  end
end
