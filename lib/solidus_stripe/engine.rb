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

      ::Spree::PermittedAttributes.source_attributes.prepend :stripe_payment_method_id
    end

    initializer "solidus_stripe.pub_sub", after: "spree.core.pub_sub" do |app|
      require "solidus_stripe/webhook/event"
      app.reloader.to_prepare do
        SolidusStripe::Webhook::Event.register(
          user_events: SolidusStripe.configuration.webhook_events,
          bus: Spree::Bus
        )
        SolidusStripe::Webhook::PaymentIntentSubscriber.new.subscribe_to(Spree::Bus)
        SolidusStripe::Webhook::ChargeSubscriber.new.subscribe_to(Spree::Bus)
      end
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
