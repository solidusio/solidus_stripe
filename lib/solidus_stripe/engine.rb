module SolidusStripe
  class Engine < Rails::Engine
    engine_name 'solidus_stripe'

    initializer "spree.payment_method.add_stripe_credit_card", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::StripeCreditCard
    end

    if SolidusSupport.backend_available?
      paths["app/views"] << "lib/views/backend"
    end

    if SolidusSupport.frontend_available?
      paths["app/views"] << "lib/views/frontend"
    end

    if SolidusSupport.api_available?
      paths["app/views"] << "lib/views/api"
    end    
  end
end
