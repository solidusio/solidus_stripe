module SolidusStripe
  class Engine < Rails::Engine
    engine_name 'solidus_stripe'

    initializer "spree.stripe.payment_method", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::Gateway::StripeGateway
    end

    if SolidusSupport.backend_available?
      paths["app/views"] << "lib/views/backend"
    end

    if SolidusSupport.frontend_available?
      paths["app/views"] << "lib/views/frontend"
    end
  end
end
