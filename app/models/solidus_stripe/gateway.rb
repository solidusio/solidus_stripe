# frozen_string_literal: true

require 'stripe'

# rubocop:disable Lint/UnusedMethodArgument, Style/MethodCallWithoutArgsParentheses
module SolidusStripe
  class Gateway
    def initialize(options)
      # Cannot use kwargs because of how the Gateway is initialized by Solidus.
      @client = Stripe::StripeClient.new(
        api_key: options.fetch(:api_key, nil),
      )
      @options = options
    end

    # Authorizes a certain amount on the provided payment source.
    def authorize(money, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Captures a certain amount from a previously authorized transaction.
    def capture(money, transaction_id, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Authorizes and captures a certain amount on the provided payment source.
    def purchase(money, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Voids a previously authorized transaction, releasing the funds that are on hold.
    # The source parameter is only needed for payment gateways that support payment profiles.
    def void(transaction_id, source, options = {})
      ActiveMerchant::Billing::Response.new()
    end

    # Refunds the provided amount on a previously captured transaction.
    # The source parameter is only needed for payment gateways that support payment profiles.
    def credit(money, source, transaction_id, options = {})
      ActiveMerchant::Billing::Response.new()
    end
  end
end
# rubocop:enable Style/MethodCallWithoutArgsParentheses, Lint/UnusedMethodArgument
