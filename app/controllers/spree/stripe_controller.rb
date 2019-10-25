# frozen_string_literal: true

module Spree
  class StripeController < Spree::BaseController
    include Core::ControllerHelpers::Order

    def confirm_payment
      # TODO find the right place for this:
      Stripe.api_key ||= Spree::PaymentMethod::StripeCreditCard.first.preferred_secret_key

      begin
        if params[:payment_method_id].present?
          # Create the PaymentIntent
          intent = Stripe::PaymentIntent.create(
            payment_method: params[:payment_method_id],
            amount: (current_order.total * 100).to_i,
            currency: current_order.currency,
            confirmation_method: 'manual',
            confirm: true,
            setup_future_usage: 'on_session',
            metadata: { order_id:  current_order.id }
          )
        elsif params[:payment_intent_id].present?
          intent = Stripe::PaymentIntent.confirm(params[:payment_intent_id])
        end
      rescue Stripe::CardError => e
        # Display error on client
        render json: { error: e.message }
        return
      end

      generate_payment_response(intent)
    end

    private

    def generate_payment_response(intent)
      # Note that if your API version is before 2019-02-11, 'requires_action'
      # appears as 'requires_source_action'.
      if %w[requires_source_action requires_action].include?(intent.status) && intent.next_action.type == 'use_stripe_sdk'
          render json: {
            requires_action: true,
            payment_intent_client_secret: intent.client_secret
          }
      elsif intent.status == 'succeeded'
        # The payment didn’t need any additional actions and is completed!
        # Handle post-payment fulfillment
        render json: { success: true }
      else
        render json: { error: 'Invalid PaymentIntent status' }, status: 500
      end
    end
  end
end
