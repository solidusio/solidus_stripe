# frozen_string_literal: true

require 'stripe'

class SolidusStripe::IntentsController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  before_action :load_payment_method

  def after_confirmation
    unless params[:payment_intent]
      return head :unprocessable_entity
    end

    unless current_order.confirm?
      redirect_to main_app.checkout_state_path(current_order.state)
      return
    end

    intent = SolidusStripe::PaymentIntent.find_by!(
      payment_method: @payment_method,
      order: current_order,
      stripe_intent_id: params[:payment_intent],
    )

    if intent.process_payment
      flash.notice = t('spree.order_processed_successfully')

      flash['order_completed'] = true

      redirect_to(
        spree_current_user ?
          main_app.order_path(current_order) :
          main_app.token_order_path(current_order, current_order.guest_token)
      )
    else
      flash[:error] = params[:error_message] || t('spree.payment_processing_failed')
      redirect_to(main_app.checkout_state_path(:payment))
    end
  end

  private

  def load_payment_method
    @payment_method = current_order(create_order_if_necessary: true)
      .available_payment_methods
      .merge(SolidusStripe::PaymentMethod.with_slug(params[:slug]))
      .first!
  end
end
