# frozen_string_literal: true

module Spree
  module SolidusStripe
    module Api
      class IntentsController < Spree::Api::BaseController
        before_action :load_order, only: :create_payment_intent
        skip_before_action :authenticate_user, if: -> { params[:guest_token].present? }

        def create_setup_intent
          create_setup_intent_result = ::SolidusStripe::CreateSetupIntentForUser.new.call(
            user: current_api_user,
            payment_method_id: params[:payment_method_id],
          )

          render json: create_setup_intent_result
        end

        def create_payment_intent
          authorize! :read, @order if current_api_user

          create_payment_intent_result = ::SolidusStripe::CreatePaymentIntentForOrder.new(
            order_id: @order.id,
            payment_method_id: params[:payment_method_id],
            stripe_payment_method_id: params[:stripe_payment_method_id]
          ).call

          render json: create_payment_intent_result
        end

        private

        def load_order
          @order = if current_api_user
                     current_api_user.last_incomplete_spree_order
                   else
                     Spree::Order.find_by!(guest_token: params[:guest_token])
                   end

          render json: { error: "Order not found" }, status: :not_found unless @order
        end
      end
    end
  end
end
