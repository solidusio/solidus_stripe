# frozen_string_literal: true

class AddStripeCustomerIdToUsers < SolidusSupport::Migration[5.1]
  def up
    add_column Spree.user_class.table_name.to_sym, :stripe_customer_id, :string, unique: true

    Spree::User.includes(bill_address: :country, ship_address: :country).find_each do |u|
      user_stripe_payment_sources = u&.wallet&.wallet_payment_sources&.select do |wps|
        wps.payment_source.payment_method.type == 'Spree::PaymentMethod::StripeCreditCard'
      end
      payment_customer_id = user_stripe_payment_sources&.map { |ps| ps&.payment_source&.gateway_customer_profile_id }.compact.last

      if payment_customer_id.present?
        u.update_column(:stripe_customer_id, payment_customer_id)
        u.update_stripe_customer
      else
        u.create_stripe_customer
      end
    end
  end

  def down
    remove_column Spree.user_class.table_name.to_sym, :stripe_customer_id 
  end
end
