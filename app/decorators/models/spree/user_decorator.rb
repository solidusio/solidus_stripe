# frozen_string_literal: true

module Spree
  module UserDecorator
    include StripeApiMethods

    def self.prepended(base)
      base.after_create :create_stripe_customer
      base.after_update :update_stripe_customer
    end

    def stripe_customer
      Stripe::Customer.retrieve(stripe_customer_id) if stripe_customer_id.present?
    end

    def create_stripe_customer
      stripe_customer = Stripe::Customer.create(self.stripe_params)
      update_column(:stripe_customer_id, stripe_customer.id)
      stripe_customer
    end

    def update_stripe_customer
      Stripe::Customer.update(stripe_customer_id, self.stripe_params)
    end

    def delete_stripe_customer
      if stripe_customer_id.present?
        deleted_user = Stripe::Customer.delete(stripe_customer_id)
        update_column(:stripe_customer_id, nil)
        deleted_user
      end
    end

    def stripe_params
      stripe_customer_params_from_addresses(bill_address, ship_address, email)
    end

    ::Spree.user_class.prepend(self)
  end
end
