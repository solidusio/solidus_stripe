# frozen_string_literal: true

module SolidusStripe
  class SetupIntent < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'

    def stripe_setup_intent(payment_method)
      payment_method.gateway.request do
        Stripe::SetupIntent.retrieve(stripe_setup_intent_id)
      end
    end
  end
end
