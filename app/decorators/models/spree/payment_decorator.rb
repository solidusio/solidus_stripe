# frozen_string_literal: true

module Spree
  module PaymentDecorator
    def gateway_order_identifier
      gateway_order_id
    end

    ::Spree::Payment.prepend(self)
  end
end
