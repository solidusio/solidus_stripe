# frozen_string_literal: true

module SolidusStripe
  class PrepareOptionsForIntentService
    attr_reader :order, :payment_method

    def self.call(...)
      new(...).call
    end

    def initialize(order, payment_method)
      @order = order
      @payment_method = payment_method
    end

    def call
      options = {
        description: "Solidus Order ID: #{order.number} (pending)",
        currency: order.currency,
        confirmation_method: 'automatic',
        capture_method: 'manual',
        confirm: true,
        setup_future_usage: 'off_session',
        metadata: { order_id: order.id },
      }
      options.merge!(connect_options) if payment_method.preferred_stripe_connect
      options
    end

    private

    def connect_options
      return unless payment_method.preferred_stripe_connect

      opts = {
        application_fee_amount: SolidusStripe.configuration.application_fee
      }

      case payment_method.preferred_connected_mode
        when 'direct_charge'
          opts.merge!(stripe_account: connected_account)
        when 'destination_charge'
          opts.merge!(transfer_data: { destination: connected_account })
      end
      opts
    end

    def connected_account
      payment_method.preferred_connected_account
    end
  end
end
