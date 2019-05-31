# frozen_string_literal: true

class UpdateStripePaymentMethodTypeToCreditCard < SolidusSupport::Migration[5.1]
  def up
    Spree::PaymentMethod.where(type: 'Spree::Gateway::StripeGateway').update_all(type: 'Spree::PaymentMethod::StripeCreditCard')

    Spree::Preference.where("#{ActiveRecord::Base.connection.quote_column_name('key')} LIKE 'spree/gateway/stripe_gateway'").each do |pref|
      pref.key = pref.key.gsub('spree/gateway/stripe_gateway', 'spree/payment_method/stripe_credit_card')
      pref.save
    end
  end

  def down
    Spree::PaymentMethod.where(type: 'Spree::PaymentMethod::StripeCreditCard').update_all(type: 'Spree::Gateway::StripeGateway')

    Spree::Preference.where("#{ActiveRecord::Base.connection.quote_column_name('key')} LIKE 'spree/payment_method/stripe_credit_card'").each do |pref|
      pref.key = pref.key.gsub('spree/payment_method/stripe_credit_card', 'spree/gateway/stripe_gateway')
      pref.save
    end
  end
end
