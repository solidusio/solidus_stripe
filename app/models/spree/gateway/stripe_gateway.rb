module Spree
  class Gateway::StripeGateway < SolidusStripe.payment_method_parent_class
    def initialize(*args)
      Spree::Deprecation.warn 'Using Spree::Gateway::StripeGateway is deprecated. ' \
        'Please use Spree::PaymentMethod::Stripe instead.'
      super
    end
  end
end
