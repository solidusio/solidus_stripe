# frozen_string_literal: true

module SolidusStripe
  class CreateIntentsPaymentService
    attr_reader :intent_id, :stripe, :controller

    delegate :request, :current_order, :params, to: :controller

    def initialize(intent_id, stripe, controller)
      @intent_id, @stripe, @controller = intent_id, stripe, controller
    end

    def call
      invalidate_previous_payment_intents_payments
      payment = create_payment
      description = "Solidus Order ID: #{payment.gateway_order_identifier}"
      stripe.update_intent(nil, intent_id, nil, description: description)
    end

    private

    def intent
      @intent ||= stripe.show_intent(intent_id, {})
    end

    def invalidate_previous_payment_intents_payments
      if stripe.v3_intents?
        current_order.payments.pending.where(payment_method: stripe).each(&:void_transaction!)
      end
    end

    def create_payment
      Spree::OrderUpdateAttributes.new(
        current_order,
        payment_params,
        request_env: request.headers.env
      ).apply

      Spree::Payment.find_by(response_code: intent_id).tap do |payment|
        payment.update!(state: :pending)
      end
    end

    def payment_params
      card = response['charges']['data'][0]['payment_method_details']['card']
      address_attributes = form_data['payment_source'][stripe.id.to_s]['address_attributes']

      {
        payments_attributes: [{
          payment_method_id: stripe.id,
          amount: current_order.total,
          response_code: intent_id,
          source_attributes: {
            month: card['exp_month'],
            year: card['exp_year'],
            cc_type: card['brand'],
            gateway_payment_profile_id: response['payment_method'],
            last_digits: card['last4'],
            name: current_order.bill_address.full_name,
            address_attributes: address_attributes
          }
        }]
      }
    end

    def response
      intent.params
    end

    def form_data
      Rack::Utils.parse_nested_query(params[:form_data])
    end
  end
end
