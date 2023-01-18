# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

module SolidusStripe
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace SolidusStripe
    engine_name 'solidus_stripe'

    initializer "solidus_stripe.add_payment_method", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << 'SolidusStripe::PaymentMethod'
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
