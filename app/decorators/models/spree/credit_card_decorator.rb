# frozen_string_literal: true

module Spree
  module CreditCardDecorator
    def cc_type=(type)
      # See https://stripe.com/docs/api/cards/object#card_object-brand,
      # active_merchant/lib/active_merchant/billing/credit_card.rb,
      # and active_merchant/lib/active_merchant/billing/credit_card_methods.rb
      # (And see also the Solidus docs at core/app/models/spree/credit_card.rb,
      # which indicate that Solidus uses ActiveMerchant conventions by default.)
      self[:cc_type] = case type
                       when 'American Express'
                         'american_express'
                       when 'Diners Club'
                         'diners_club'
                       when 'Discover'
                         'discover'
                       when 'JCB'
                         'jcb'
                       when 'MasterCard'
                         'master'
                       when 'UnionPay'
                         'unionpay'
                       when 'Visa'
                         'visa'
                       when 'Unknown'
                         super('')
                       else
                         super(type)
                       end
    end

    ::Spree::CreditCard.prepend(self)
  end
end
