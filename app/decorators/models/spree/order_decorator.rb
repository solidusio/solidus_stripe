# frozen_string_literal: true

module Spree
  module OrderDecorator
    include StripeApiMethods

    def stripe_customer_params
      stripe_customer_params_from_addresses(bill_address, ship_address, email)
    end

    ::Spree::Order.prepend(self)
  end
end
