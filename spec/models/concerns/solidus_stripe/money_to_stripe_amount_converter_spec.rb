# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

# rubocop:disable Style/NumericLiterals
RSpec.describe SolidusStripe::MoneyToStripeAmountConverter do
  describe '.to_stripe_amount' do
    context 'with zero decimal currencies' do
      it 'returns the same unit amount' do
        (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
          expect(described_class.to_stripe_amount(12345, currency).to_i).to eq(12345)
        end
      end
    end

    context 'with three decimal currencies' do
      it 'returns the same subunit amount' do
        described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
          expect(described_class.to_stripe_amount(12_345, currency).to_i).to eq(12_345)
        end
      end
    end

    context 'with special cases' do
      it 'treats them accordingly' do
        expect(described_class.to_stripe_amount(255, 'MGA').to_i).to eq(51)
        expect(described_class.to_stripe_amount(1_2345, 'HUF').to_i).to eq(12_345_00)
        expect(described_class.to_stripe_amount(12_3450_00, 'UGX').to_i).to eq(123_450_00)
        expect(described_class.to_stripe_amount(1_2345_00, 'TWD').to_i).to eq(12_345_00)
      end
    end

    context 'with default as two decimal currencies' do
      it 'returns the same subunit amount' do
        %w[USD EUR ILS MXN TWD].each do |currency|
          expect(described_class.to_stripe_amount(123_45, currency).to_i).to eq(123_45)
        end
      end
    end
  end

  describe '.to_solidus_amount' do
    context 'with zero decimal currencies' do
      it 'returns the same unit amount' do
        (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
          expect(described_class.to_solidus_amount(12345, currency).to_i).to eq(12345)
        end
      end
    end

    context 'with three decimal currencies' do
      it 'returns the same subunit amount' do
        described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
          expect(described_class.to_solidus_amount(12_345, currency).to_i).to eq(12_345)
        end
      end
    end

    context 'with special cases' do
      it 'treats them accordingly' do
        expect(described_class.to_solidus_amount(51, 'MGA').to_i).to eq(255)
        expect(described_class.to_solidus_amount(12_345_00, 'HUF').to_i).to eq(1_2345)
        expect(described_class.to_solidus_amount(123_450_00, 'UGX').to_i).to eq(12_3450_00)
        expect(described_class.to_solidus_amount(12_345_00, 'TWD').to_i).to eq(1_2345_00)
      end
    end

    context 'with default as two decimal currencies' do
      it 'returns the same subunit amount' do
        %w[USD EUR ILS MXN TWD].each do |currency|
          expect(described_class.to_solidus_amount(123_45, currency).to_i).to eq(123_45)
        end
      end
    end
  end
end
# rubocop:enable Style/NumericLiterals
