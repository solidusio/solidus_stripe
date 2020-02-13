# frozen_string_literal: true

require 'spree/core'

module SolidusStripe
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions::Decorators

    isolate_namespace Spree

    engine_name 'solidus_stripe'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    if SolidusSupport.backend_available?
      paths["app/views"] << "lib/views/backend"
    end

    if SolidusSupport.frontend_available?
      paths["app/views"] << "lib/views/frontend"
      config.assets.precompile += ['solidus_stripe/stripe-init.js']
    end

    if SolidusSupport.api_available?
      paths["app/views"] << "lib/views/api"
    end

    initializer "spree.payment_method.add_stripe_credit_card", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::StripeCreditCard
    end
  end
end
