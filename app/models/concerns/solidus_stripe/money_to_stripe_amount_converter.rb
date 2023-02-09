# frozen_string_literal: true

module SolidusStripe::MoneyToStripeAmountConverter
  extend ActiveSupport::Concern
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
    solidus_subunit_to_unit, stripe_subunit_to_unit = subunit_to_unit(currency)

    if stripe_subunit_to_unit == solidus_subunit_to_unit
      fractional
    else
      (fractional / solidus_subunit_to_unit.to_d) * stripe_subunit_to_unit.to_d
    end
  end

  def to_solidus_amount(fractional, currency)
    solidus_subunit_to_unit, stripe_subunit_to_unit = subunit_to_unit(currency)

    if stripe_subunit_to_unit == solidus_subunit_to_unit
      fractional
    else
      (fractional / stripe_subunit_to_unit.to_d) * solidus_subunit_to_unit.to_d
    end
  end

  private

  def subunit_to_unit(currency)
    solidus_subunit_to_unit = ::Money::Currency.new(currency).subunit_to_unit
    stripe_subunit_to_unit =
      case currency.to_s.upcase
      when *ZERO_DECIMAL_CURRENCIES then 1
      when *THREE_DECIMAL_CURRENCIES then 1000
      when *DIVISIBLE_BY_100 then 100
      else 100
      end

    [solidus_subunit_to_unit, stripe_subunit_to_unit]
  end
end
