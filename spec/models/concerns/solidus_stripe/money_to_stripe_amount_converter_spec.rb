# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

# rubocop:disable Style/NumericLiterals
RSpec.describe SolidusStripe::MoneyToStripeAmountConverter do
  describe '.to_stripe_amount' do
    let(:custom_message) do
      ->(actual, expected, currency) { "Expected #{currency} to be #{expected} but got #{actual}" }
    end

    context 'with zero decimal currencies' do
      it 'returns the same unit amount' do
        (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
          actual = described_class.to_stripe_amount(12345, currency).to_i

          expected = 12345
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end

    context 'with three decimal currencies' do
      it 'returns the same subunit amount' do
        described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
          actual = described_class.to_stripe_amount(12_345, currency).to_i

          expected = 12_345
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end

    context 'with special cases' do
      it 'returns the amount divided by 5 (iraimbilanja to ariary) when currency is MGA' do
        expect(described_class.to_stripe_amount(255, 'MGA').to_i).to eq(51)
      end

      it 'returns the amount as a two decimal currency when currency is HUF' do
        expect(described_class.to_stripe_amount(1_2345, 'HUF').to_i).to eq(12_345_00)
      end

      it 'returns the same amount as a zero decimal currency when currency is UGX' do
        expect(described_class.to_stripe_amount(12_3450_00, 'UGX').to_i).to eq(123_450_00)
      end

      it 'returns the same amount as a zero decimal currency when currency is TWD' do
        expect(described_class.to_stripe_amount(1_2345_00, 'TWD').to_i).to eq(12_345_00)
      end
    end

    context 'with default as two decimal currencies' do
      it 'returns the same subunit amount' do
        %w[USD EUR ILS MXN TWD].each do |currency|
          actual = described_class.to_stripe_amount(123_45, currency).to_i

          expected = 123_45
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end
  end

  describe '.to_solidus_amount' do
    let(:custom_message) do
      ->(actual, expected, currency) { "Expected #{currency} to be #{expected} but got #{actual}" }
    end

    context 'with zero decimal currencies' do
      it 'returns the same unit amount' do
        (described_class::ZERO_DECIMAL_CURRENCIES - %w[MGA]).each do |currency|
          actual = described_class.to_stripe_amount(12345, currency).to_i

          expected = 12345
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end

    context 'with three decimal currencies' do
      it 'returns the same subunit amount' do
        described_class::THREE_DECIMAL_CURRENCIES.each do |currency|
          actual = described_class.to_solidus_amount(12_345, currency).to_i

          expected = 12_345
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end

    context 'with special cases' do
      it 'returns the amount multiplied by 5 (ariary to iraimbilanja) when currency is MGA' do
        expect(described_class.to_solidus_amount(51, 'MGA').to_i).to eq(255)
      end

      it 'returns the amount without the last two digits when currency is HUF' do
        expect(described_class.to_solidus_amount(12_345_00, 'HUF').to_i).to eq(1_2345)
      end

      it 'returns the amount as a zero decimal currency when currency is UGX' do
        expect(described_class.to_solidus_amount(123_450_00, 'UGX').to_i).to eq(12_3450_00)
      end

      it 'returns the amount as a zero decimal currency when currency is TWD' do
        expect(described_class.to_solidus_amount(12_345_00, 'TWD').to_i).to eq(1_2345_00)
      end
    end

    context 'with default as two decimal currencies' do
      it 'returns the same subunit amount' do
        %w[USD EUR ILS MXN TWD].each do |currency|
          actual = described_class.to_solidus_amount(123_45, currency).to_i

          expected = 123_45
          expect(actual).to eq(expected), custom_message.call(actual, expected, currency)
        end
      end
    end
  end
end
# rubocop:enable Style/NumericLiterals
