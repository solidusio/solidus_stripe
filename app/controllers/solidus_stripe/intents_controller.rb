# frozen_string_literal: true

module SolidusStripe
  class IntentsController < Spree::BaseController
    include Spree::Core::ControllerHelpers::Order

    def confirm
      begin
        if params[:stripe_payment_method_id].present?
          intent = stripe.create_intent(
            100,
            params[:stripe_payment_method_id],
            description: "Card pre-authorization for order #{current_order.number}",
            currency: current_order.currency,
            confirmation_method: 'manual',
            capture_method: 'manual',
            confirm: true,
            setup_future_usage: 'off_session',
            metadata: { order_id: current_order.id }
          )
        elsif params[:stripe_payment_intent_id].present?
          intent = stripe.confirm_intent(params[:stripe_payment_intent_id], nil)
        end
      rescue Stripe::CardError => e
        render json: { error: e.message }, status: 500
        return
      end

      generate_payment_response(intent)
    end

    private

    def stripe
      @stripe ||= Spree::PaymentMethod::StripeCreditCard.find(params[:spree_payment_method_id])
    end

    def generate_payment_response(intent)
      response = intent.params
      # Note that if your API version is before 2019-02-11, 'requires_action'
      # appears as 'requires_source_action'.
      if %w[requires_source_action requires_action].include?(response['status']) && response['next_action']['type'] == 'use_stripe_sdk'
          render json: {
            requires_action: true,
            stripe_payment_intent_client_secret: response['client_secret']
          }
      elsif %w[requires_capture succeeded].include?(response['status'])
        render json: { success: true }
      else
        render json: { error: response['error']['message'] }, status: 500
      end
    end
  end
end
