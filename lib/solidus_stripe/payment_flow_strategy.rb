# frozen_string_literal: true

module SolidusStripe::PaymentFlowStrategy
  class SetupIntent
    attr_reader :order, :payment_method, :intent_options

    def initialize(order:, payment_method:)
      @order = order
      @payment_method = payment_method
      @intent_options = {}
    end

    def intent_class
      SolidusStripe::SetupIntent
    end

    def skip_confirm_step?
      false
    end

    def payment_intent_creation_options
      {}
    end

    def intent_flow
      'setup'
    end

    def retrieve_or_create_stripe_intent
      intent_class.retrieve_stripe_intent(
        payment_method: payment_method, order: order
      ) || intent_class.create_stripe_intent(
        payment_method: payment_method, order: order, stripe_intent_options: intent_options
      )
    end
  end

  class PaymentIntent
    attr_reader :order, :payment_method, :intent_options

    def initialize(order:, payment_method:)
      @order = order
      @payment_method = payment_method
      @intent_options = {
        setup_future_usage: order.user ? 'off_session' : nil
      }
    end

    def intent_class
      SolidusStripe::PaymentIntent
    end

    def skip_confirm_step?
      true
    end

    def intent_flow
      'payment'
    end

    def retrieve_or_create_stripe_intent
      intent_class.retrieve_stripe_intent(
        payment_method: payment_method, order: order
      ) || intent_class.create_stripe_intent(
        payment_method: payment_method, order: order, stripe_intent_options: intent_options.compact
      )
    end
  end

  def self.for(payment_method:, order:)
    SolidusStripe.configuration.payment_flow_strategy.new(
      payment_method: payment_method,
      order: order,
    )
  end
end
