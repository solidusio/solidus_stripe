module StripeApiMethods
  extend ActiveSupport::Concern

  def stripe_customer_params_from_addresses(bill_address, ship_address, email)
    {
      address: stripe_address_hash(bill_address),
      email: email,
      name: bill_address.try(:name) || bill_address&.full_name,
      phone: bill_address&.phone,
      shipping: {
        address: stripe_address_hash(ship_address),
        name: ship_address.try(:name) || ship_address&.full_name,
        phone: ship_address&.phone
      }
    }
  end

  def stripe_address_hash(address)
    {
      city: address&.city,
      country: address&.country&.iso,
      line1: address&.address1,
      line2: address&.address2,
      postal_code: address&.zipcode,
      state: address&.state_text
    }
  end
end
