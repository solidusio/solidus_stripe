# frozen_string_literal: true

module Spree
  module PaymentDecorator
    def gateway_order_identifier
      gateway_order_id
    end

    def handle_void_response(response)
      record_response(response)

      if response.success? ||
         (response.params['error'] && response.params['error']['code'] == 'payment_intent_unexpected_state')
        self.response_code = response.authorization
        void
      else
        gateway_error(response)
      end
    end

    ::Spree::Payment.prepend(self)
  end
end
