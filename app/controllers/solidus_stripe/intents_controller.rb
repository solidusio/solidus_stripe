# frozen_string_literal: true

require 'stripe'

class SolidusStripe::IntentsController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  before_action :load_payment_method

  def after_confirmation
    unless %w[confirm payment].include?(current_order.state.to_s)
      redirect_to main_app.checkout_state_path(current_order.state)
      return
    end

    # Check if this is needed. This was added to be sure the order
    # in in the right step.
    current_order.state = :payment

    # TODO: understand how to handle webhooks. At this stage, we might receive a webhook
    # with the confirmation of the setup intent. We need to be sure we are not creating
    # the payment twice.
    # https://stripe.com/docs/payments/intents?intent=setup#setup-intent-webhooks

    current_order.next!

    case
    when params[:setup_intent]
      intent = SolidusStripe::SetupIntent.find_by!(
        payment_method: @payment_method,
        order: current_order,
        stripe_intent_id: params[:setup_intent],
      )
    when params[:payment_intent]
      intent = SolidusStripe::PaymentIntent.find_by!(
        payment_method: @payment_method,
        order: current_order,
        stripe_intent_id: params[:payment_intent],
      )
    else
      return head :unprocessable_entity
    end

    payment = intent.create_payment!(
      amount: current_order.total, # TODO: double check, remove store credit?
      add_to_wallet: true
    )

    SolidusStripe::LogEntries.payment_log(
      payment,
      success: true,
      message: "Reached return URL",
      data: intent.stripe_intent,
    )

    strategy = SolidusStripe::PaymentFlowStrategy.for(
      payment_method: @payment_method,
      order: order,
    )

    if strategy.skip_confirm_step?
      flash.notice = t('spree.order_processed_successfully')
      flash['order_completed'] = true
      current_order.complete!
      redirect_to main_app.token_order_path(current_order, current_order.guest_token)
    else
      flash[:notice] = t(".intent_status.#{intent.stripe_intent.status}")
      redirect_to main_app.checkout_state_path(current_order.state)
    end
  end

  private

  def load_payment_method
    @payment_method = current_order(create_order_if_necessary: true)
      .available_payment_methods.find(params[:payment_method_id])
  end
end
