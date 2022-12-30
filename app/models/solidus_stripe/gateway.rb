# frozen_string_literal: true

require 'stripe'

# rubocop:disable Lint/UnusedMethodArgument, Style/MethodCallWithoutArgsParentheses
module SolidusStripe
  class Gateway
    def initialize(options)
      # Cannot use kwargs because of how the Gateway is initialized by Solidus.
      @client = Stripe::StripeClient.new(
        api_key: options.fetch(:api_key, nil),
      )
      @options = options
    end

    # Authorizes a certain amount on the provided payment source.
    def authorize(money, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Captures a certain amount from a previously authorized transaction.
    def capture(money, transaction_id, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Authorizes and captures a certain amount on the provided payment source.
    def purchase(money, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Voids a previously authorized transaction, releasing the funds that are on hold.
    # The source parameter is only needed for payment gateways that support payment profiles.
    def void(transaction_id, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Refunds the provided amount on a previously captured transaction.
    # The source parameter is only needed for payment gateways that support payment profiles.
    def credit(money, source, transaction_id, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    module MoneyToStripeAmountConverter
      extend self

      ZERO_DECIMAL_CURRENCIES = %w[
        BIF
        CLP
        DJF
        GNF
        JPY
        KMF
        KRW
        MGA
        PYG
        RWF
        UGX
        VND
        VUV
        XAF
        XOF
        XPF
      ].freeze

      THREE_DECIMAL_CURRENCIES = %w[
        BHD
        JOD
        KWD
        OMR
        TND
      ].freeze

      # special currencies that are represented in cents but
      # should be divisible by 100, thus making them integer only.
      DIVISIBLE_BY_100 = %w[
        HUF
        TWD
        UGX
      ].freeze

      # Solidus will provide a "fractional" amount, that is specific for each currency
      # following the configurationo defined in the Money gem.
      #
      # Stripe uses the "smallest currency unit",
      # (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency)
      # https://stripe.com/docs/currencies#zero-decimal
      #
      # We need to ensure the fractional amount is considering the same number of decimals.
      def to_stripe_amount(fractional, currency)
        money_subunit_to_unit = ::Money::Currency.new(currency).subunit_to_unit
        stripe_subunit_to_unit =
          case currency.to_s.upcase
          when *ZERO_DECIMAL_CURRENCIES then 1
          when *THREE_DECIMAL_CURRENCIES then 1000
          when *DIVISIBLE_BY_100 then 100
          else 100
          end

        if stripe_subunit_to_unit == money_subunit_to_unit
          fractional
        else
          (fractional / money_subunit_to_unit.to_d) * stripe_subunit_to_unit
        end
      end
    end
  end
end
# rubocop:enable Style/MethodCallWithoutArgsParentheses, Lint/UnusedMethodArgument
