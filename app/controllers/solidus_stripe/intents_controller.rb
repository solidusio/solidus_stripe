# frozen_string_literal: true

module SolidusStripe
  class IntentsController < Spree::BaseController
    include Spree::Core::ControllerHelpers::Order

    def confirm
      begin
        @intent = create_payment_intent
      rescue Stripe::CardError => e
        render json: { error: e.message }, status: 500
        return
      end

      generate_payment_response
    end

    def create_payment
      SolidusStripe::CreateIntentsPaymentService.new(params[:stripe_payment_intent_id], stripe, self).call
      render json: { success: true }
    end

    private

    def stripe
      @stripe ||= Spree::PaymentMethod::StripeCreditCard.find(params[:spree_payment_method_id])
    end

    def generate_payment_response
      response = @intent.params
      # Note that if your API version is before 2019-02-11, 'requires_action'
      # appears as 'requires_source_action'.
      if %w[requires_source_action requires_action].include?(response['status']) && response['next_action']['type'] == 'use_stripe_sdk'
        render json: {
          requires_action: true,
          stripe_payment_intent_client_secret: response['client_secret']
        }
      elsif response['status'] == 'requires_capture'
        render json: {
          success: true,
          requires_capture: true,
          stripe_payment_intent_id: response['id']
        }
      else
        render json: { error: response['error']['message'] }, status: 500
      end
    end

    def create_payment_intent
      stripe.create_intent(
        (current_order.total * 100).to_i,
        params[:stripe_payment_method_id],
        description: "Solidus Order ID: #{current_order.number} (pending)",
        currency: current_order.currency,
        confirmation_method: 'automatic',
        capture_method: 'manual',
        confirm: true,
        setup_future_usage: 'off_session',
        metadata: { order_id: current_order.id }
      )
    end
  end
end
