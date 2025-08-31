# frozen_string_literal: true

module SolidusStripe
  module Spree
    module OrderDecorator
      def self.prepended(base)
        base.class_eval do
          # Clean up payment intents when order is destroyed
          # This prevents foreign key constraint errors during order merging
          has_many :solidus_stripe_payment_intents,
                   class_name: 'SolidusStripe::PaymentIntent',
                   foreign_key: :order_id,
                   dependent: :destroy
        end
      end

      ::Spree::Order.prepend(self)
    end
  end
end