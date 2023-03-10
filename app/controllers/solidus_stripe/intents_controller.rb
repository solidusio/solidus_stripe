# frozen_string_literal: true

require 'stripe'

class SolidusStripe::IntentsController < Spree::BaseController
  include Spree::Core::ControllerHelpers::Order

  before_action :load_payment_method

  Strategy = Struct.new(:order, :payment_method) do
    alias_method :current_order, :order
  end

  class PaymentIntentStrategy < Strategy
    def intent
      @intent ||= payment_method.find_payment_intent_for_order(current_order)
    end

    def create_payment!
      current_order.payments.create!(
        state: 'pending',
        payment_method: @payment_method,
        amount: current_order.total, # TODO: double check, remove store credit?
        response_code: intent.id,
        source: @payment_method.payment_source_class.new(
          payment_method: @payment_method
        ),
      )
    end

    def add_payment_to_the_user_wallet(payment)
      return unless current_order.user
      return if intent.setup_future_usage.blank?

      payment.source.update(stripe_payment_method_id: intent.payment_method)
      current_order.user.wallet.add payment.source
    end

    def skip_confirm_step?
      true
      # @payment_method.skip_confirm_step?
    end
  end

  class SetupIntentStrategy < Strategy
    def intent
      @intent ||= payment_method.find_setup_intent_for_order(current_order)
    end

    def create_payment!
      current_order.payments.create!(
        payment_method: @payment_method,
        amount: current_order.total, # TODO: double check, remove store credit?
        source: @payment_method.payment_source_class.new(
          stripe_payment_method_id: intent.payment_method,
          payment_method: @payment_method,
        )
      )
    end

    def add_payment_to_the_user_wallet(payment)
      return unless current_order.user

      current_order.user.wallet.add payment.source
    end

    def skip_confirm_step?
      true
      # @payment_method.skip_confirm_step?
    end

    def call_after_intent_change(log_message:)
      raise "bad order state" unless %w[confirm payment].include?(current_order.state.to_s)

      # Check if this is needed. This was added to be sure the order in in the right step.
      current_order.state = :payment
      payment = create_payment!
      SolidusStripe::LogEntries.payment_log(
        result.payment,
        success: true,
        message: log_message,
        data: handler.intent,
      )
      current_order.next!
      add_payment_to_the_user_wallet(payment)
      current_order.complete! if skip_confirm_step?

      Result.new(payment: payment)
    end
  end

  def handler_for_intent_id(intent_id)
    klass =
      case intent_id
      when /^pi_/ then PaymentIntentStrategy
      when /^seti_/ then SetupIntentStrategy
      else raise
      end
    klass.new(current_order, @payment_method).tap do |handler|
      raise "The intent id doesn't match" if intent_id != handler.intent.id
    end
  end

  Result = Struct.new(:successful)

  def after_confirmation
    handler = handler_for_intent_id(intent_param)
    result = handler.call_after_intent_change(log_message: "Reached return URL")

    if result.successful
      if current_order.completed?
        flash.notice = t('spree.order_processed_successfully')
        flash['order_completed'] = true
        redirect_to main_app.token_order_path(current_order, current_order.guest_token)
      else
        flash[:notice] = t(".intent_status.#{intent.status}")
        redirect_to main_app.checkout_state_path(current_order.state)
      end
    else
      flash[:error] = "Couldn't complete the payment"
      redirect_to main_app.checkout_state_path(current_order.state)
    end
  end

  private

  def load_payment_method
    @payment_method = current_order(create_order_if_necessary: true)
      .available_payment_methods.find(params[:payment_method_id])
  end

  def intent_param
    params[:setup_intent] || params[:payment_intent] || raise
  end
end
