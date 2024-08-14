# frozen_string_literal: true

module SolidusStripe
  class FindOrCreateCustomerForUser
    attr_reader :user, :payment_method

    def initialize(user:, payment_method:)
      @user = user
      @payment_method = payment_method
    end

    def call
      customer = SolidusStripe::Customer.find_or_create_by!(source: user, payment_method: payment_method)
      return customer if customer.stripe_id.present?

      stripe_customer = customer.create_stripe_customer
      customer.update!(stripe_id: stripe_customer.id)
      customer
    end
  end
end
