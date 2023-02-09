# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

# rubocop:disable Style/NumericLiterals
RSpec.describe SolidusStripe::MoneyToStripeAmountConverter do
  describe '.to_stripe_amount' do
    it 'converts to the fractional expected by stripe' do
      (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
        expect([currency, described_class.to_stripe_amount(12345, currency).to_i]).to eq([currency, 12345])
      end

      %w[USD EUR ILS MXN TWD].each do |currency| # 2 decimals on both sides, default case
        expect([currency, described_class.to_stripe_amount(123_45, currency).to_i]).to eq([currency, 123_45])
      end

      described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
        expect([currency, described_class.to_stripe_amount(12_345, currency).to_i]).to eq([currency, 12_345])
      end

      # Special cases
      expect(['MGA', described_class.to_stripe_amount(255, 'MGA').to_i]).to eq(['MGA', 51])
      expect(['HUF', described_class.to_stripe_amount(1_2345, 'HUF').to_i]).to eq(['HUF', 12_345_00])
      expect(['UGX', described_class.to_stripe_amount(12_3450_00, 'UGX').to_i]).to eq(['UGX', 123_450_00])
      expect(['TWD', described_class.to_stripe_amount(1_2345_00, 'TWD').to_i]).to eq(['TWD', 12_345_00])
    end
  end

  describe '.to_solidus_amount' do
    it 'converts to the fractional expected by stripe' do
      (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
        expect([currency, described_class.to_solidus_amount(12345, currency).to_i]).to eq([currency, 12345])
      end

      %w[USD EUR ILS MXN TWD].each do |currency| # 2 decimals on both sides, default case
        expect([currency, described_class.to_solidus_amount(123_45, currency).to_i]).to eq([currency, 123_45])
      end

      described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
        expect([currency, described_class.to_solidus_amount(12_345, currency).to_i]).to eq([currency, 12_345])
      end

      # Special cases
      expect(['MGA', described_class.to_solidus_amount(51, 'MGA').to_i]).to eq(['MGA', 255])
      expect(['HUF', described_class.to_solidus_amount(12_345_00, 'HUF').to_i]).to eq(['HUF', 1_2345])
      expect(['UGX', described_class.to_solidus_amount(123_450_00, 'UGX').to_i]).to eq(['UGX', 12_3450_00])
      expect(['TWD', described_class.to_solidus_amount(12_345_00, 'TWD').to_i]).to eq(['TWD', 1_2345_00])
    end
  end
end
# rubocop:enable Style/NumericLiterals
