# frozen_string_literal: true

require 'stripe'

class SolidusStripe::IntentsController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  before_action :load_payment_method

  def setup_confirmation
    intent_class = SolidusStripe::SetupIntent
    intent = intent_class.find_by!(
      payment_method: @payment_method,
      order: current_order,
    ).stripe_intent

    if params[:setup_intent] != intent.id
      raise "The setup intent id doesn't match"
    end

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

    payment = current_order.payments.create!(
      payment_method: @payment_method,
      amount: current_order.total, # TODO: double check, remove store credit?
      source: @payment_method.payment_source_class.new(
        stripe_payment_method_id: intent.payment_method,
        payment_method: @payment_method,
      )
    )

    SolidusStripe::LogEntries.payment_log(
      payment,
      success: true,
      message: "Reached return URL",
      data: intent,
    )

    current_order.next!
    add_setup_intent_to_the_user_wallet(intent, payment)

    flash[:notice] = t(".intent_status.#{intent.status}")
    redirect_to main_app.checkout_state_path(current_order.state)
  end

  def payment_confirmation
    intent_class = SolidusStripe::PaymentIntent
    intent = intent_class.find_by!(
      payment_method: @payment_method,
      order: current_order,
    ).stripe_intent

    if params[:payment_intent] != intent.id
      raise "The payment intent id doesn't match"
    end

    unless %w[confirm payment].include?(current_order.state.to_s)
      redirect_to main_app.checkout_state_path(current_order.state)
      return
    end

    current_order.state = :payment

    payment = current_order.payments.create!(
      state: 'pending',
      payment_method: @payment_method,
      amount: current_order.total, # TODO: double check, remove store credit?
      response_code: intent.id,
      source: @payment_method.payment_source_class.new(
        payment_method: @payment_method
      ),
    )

    SolidusStripe::LogEntries.payment_log(
      payment,
      success: true,
      message: "Reached return URL",
      data: intent,
    )

    current_order.next!
    add_payment_source_to_the_user_wallet(payment, intent)

    if @payment_method.skip_confirm_step?
      flash.notice = t('spree.order_processed_successfully')
      flash['order_completed'] = true
      current_order.complete!
      redirect_to main_app.token_order_path(current_order, current_order.guest_token)
    else
      flash[:notice] = t(".payment_intent_status.#{intent.status}")
      redirect_to main_app.checkout_state_path(current_order.state)
    end
  end

  private

  def add_setup_intent_to_the_user_wallet(_intent, payment)
    return unless current_order.user

    current_order.user.wallet.add payment.source
  end

  def add_payment_source_to_the_user_wallet(payment, intent)
    return unless current_order.user
    return if intent.setup_future_usage.blank?

    payment.source.update(stripe_payment_method_id: intent.payment_method)
    current_order.user.wallet.add payment.source
  end

  def ensure_state_is(object, state)
    return if object.state.to_s == state.to_s

    raise "unexpected object state #{object.state}, should have been #{state}"
  end

  def load_payment_method
    @payment_method = current_order(create_order_if_necessary: true)
      .available_payment_methods.find(params[:payment_method_id])
  end
end
