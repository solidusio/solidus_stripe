require "active_merchant"
require "solidus_core"
require "solidus_support"
require "solidus_stripe/engine"
require "solidus_stripe/version"

module SolidusStripe
  def self.payment_method_parent_class
    if SolidusSupport.solidus_gem_version < Gem::Version.new('2.3.x')
      Spree::Gateway
    else
      Spree::PaymentMethod::CreditCard
    end
  end
end
