# frozen_string_literal: true

module Spree
  class PaymentMethod
    class StripeCreditCard < Spree::PaymentMethod::CreditCard
      preference :secret_key, :string
      preference :publishable_key, :string
      preference :stripe_country, :string
      preference :v3_elements, :boolean
      preference :v3_intents, :boolean

      CARD_TYPE_MAPPING = {
        'American Express' => 'american_express',
        'Diners Club' => 'diners_club',
        'Visa' => 'visa'
      }

      delegate :create_intent, :update_intent, :confirm_intent, :show_intent, to: :gateway

      def stripe_config(order)
        {
          id: id,
          publishable_key: preferred_publishable_key
        }.tap do |config|
          config.merge!(
            payment_request: {
              country: preferred_stripe_country,
              currency: order.currency.downcase,
              label: "Payment for order #{order.number}",
              amount: (order.total * 100).to_i
            }
          ) if payment_request?
        end
      end

      def partial_name
        'stripe'
      end

      def v3_elements?
        !!preferred_v3_elements
      end

      def payment_request?
        v3_intents? && preferred_stripe_country.present?
      end

      def v3_intents?
        !!preferred_v3_intents
      end

      def gateway_class
        if v3_intents?
          ActiveMerchant::Billing::StripePaymentIntentsGateway
        else
          ActiveMerchant::Billing::StripeGateway
        end
      end

      def payment_profiles_supported?
        true
      end

      def purchase(money, creditcard, transaction_options)
        gateway.purchase(*options_for_purchase_or_auth(money, creditcard, transaction_options))
      end

      def authorize(money, creditcard, transaction_options)
        gateway.authorize(*options_for_purchase_or_auth(money, creditcard, transaction_options))
      end

      def capture(money, response_code, transaction_options)
        gateway.capture(money, response_code, transaction_options)
      end

      def credit(money, _creditcard, response_code, _transaction_options)
        gateway.refund(money, response_code, {})
      end

      def void(response_code, _creditcard, _transaction_options)
        gateway.void(response_code, {})
      end

      def payment_intents_refund_reason
        Spree::RefundReason.where(name: Spree::Payment::Cancellation::DEFAULT_REASON).first_or_create
      end

      def try_void(payment)
        if v3_intents? && payment.completed?
          payment.refunds.create!(
            amount: payment.credit_allowed,
            reason: payment_intents_refund_reason
          ).response
        else
          void(payment.response_code, nil, nil)
        end
      end

      def cancel(response_code)
        gateway.void(response_code, {})
      end

      def create_profile(payment)
        return unless payment.source.gateway_customer_profile_id.nil?

        order = payment.order
        user = payment.source.user || order.user

        source = update_source!(payment.source)

        # Check to see whether a user's previous payment sources
        # are linked to a Stripe account
        user_stripe_payment_sources = user&.wallet&.wallet_payment_sources&.select do |wps|
          wps.payment_source.payment_method.type == 'Spree::PaymentMethod::StripeCreditCard'
        end
        stripe_customer = if user_stripe_payment_sources.present?
                            customer_id = user_stripe_payment_sources.map { |ps| ps.payment_source&.gateway_customer_profile_id }.compact.last
                            Stripe::Customer.retrieve(customer_id)
                          else
                            bill_address = user&.bill_address || order.bill_address
                            ship_address = user&.ship_address || order.ship_address
                            Stripe::Customer.create({
                              address: stripe_address_hash(bill_address),
                              email: user&.email || order.email,
                              # full_name is deprecated in favor of name as of Solidus 3.0
                              name: bill_address.try(:name) || bill_address&.full_name,
                              phone: bill_address&.phone,
                              shipping: {
                                address: stripe_address_hash(ship_address),
                                # full_name is deprecated in favor of name as of Solidus 3.0
                                name: ship_address.try(:name) || ship_address&.full_name,
                                phone: ship_address&.phone
                              }.reject { |_, v| v.blank? }
                            }.reject { |_, v| v.blank? })
                          end

        # Create new Stripe card / payment method and attach to
        # (new or existing) Stripe profile
        if source.gateway_payment_profile_id&.starts_with?('pm_')
          stripe_payment_method = Stripe::PaymentMethod.attach(source.gateway_payment_profile_id, customer: stripe_customer)
          payment.source.update!(
            cc_type: stripe_payment_method.card.brand,
            gateway_customer_profile_id: stripe_customer.id,
            gateway_payment_profile_id: stripe_payment_method.id
          )
        elsif source.gateway_payment_profile_id&.starts_with?('tok_')
          stripe_card = Stripe::Customer.create_source(stripe_customer.id, source: source.gateway_payment_profile_id)
          payment.source.update!(
            cc_type: stripe_card.brand,
            gateway_customer_profile_id: stripe_customer.id,
            gateway_payment_profile_id: stripe_card.id
          )
        end
      end

      private

      # In this gateway, what we call 'secret_key' is the 'login'
      def options
        options = super
        options.merge(login: preferred_secret_key)
      end

      def options_for_purchase_or_auth(money, creditcard, transaction_options)
        options = {}
        options[:description] = "Solidus Order ID: #{transaction_options[:order_id]}"
        options[:currency] = transaction_options[:currency]
        options[:off_session] = true if v3_intents?

        if customer = creditcard.gateway_customer_profile_id
          options[:customer] = customer
        end
        if token_or_card_id = creditcard.gateway_payment_profile_id
          # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
          # The Stripe ActiveMerchant gateway supports passing the customer_id and credit_card id
          # https://github.com/Shopify/active_merchant/issues/770
          creditcard = token_or_card_id
        end
        [money, creditcard, options]
      end

      def stripe_address_hash(address)
        {
          city: address&.city,
          country: address&.country&.iso,
          line1: address&.address1,
          line2: address&.address2,
          postal_code: address&.zipcode,
          state: address&.state_text
        }.compact
      end

      def update_source!(source)
        source.cc_type = CARD_TYPE_MAPPING[source.cc_type] if CARD_TYPE_MAPPING.include?(source.cc_type)
        source
      end
    end
  end
end
