# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe 'SolidusStripe Orders Payments', :js do
  include SolidusStripe::BackendTestHelper
  stub_authorization!

  context 'with successful payment operations' do
    it 'navigates to the payments page' do
      payment = create_authorized_payment
      visit_payments_page

      expects_page_to_display_payment(payment)
    end

    it 'displays log entries for a payment' do
      payment = create(:stripe_payment, :captured, order: order, payment_method: payment_method)

      visit_payment_page(payment)

      expects_page_to_display_log_messages(["PaymentIntent was confirmed and captured successfully"])
    end

    it 'captures an authorized payment successfully' do
      payment = create_authorized_payment
      visit_payments_page

      capture_payment

      expects_page_to_display_successfully_captured_payment(payment)
      expects_payment_to_have_correct_capture_amount_on_stripe(payment, payment.amount)
    end

    it 'voids a payment from an order' do
      payment = create_authorized_payment
      visit_payments_page

      void_payment

      expects_page_to_display_successfully_voided_payment(payment)
      expects_payment_to_be_voided_on_stripe(payment)
    end

    it 'refunds a payment from an order' do
      payment = create_captured_payment
      visit_payments_page

      refund_payment

      expects_page_to_display_successfully_refunded_payment(payment)
      expects_payment_to_be_refunded_on_stripe(payment, payment.amount)
    end

    it 'partially refunds a payment from an order' do
      payment = create_captured_payment
      visit_payments_page

      refund_reason = create(:refund_reason)
      partial_refund_amount = 25
      partially_refund_payment(refund_reason, partial_refund_amount)

      expects_page_to_display_successfully_partially_refunded_payment(payment, partial_refund_amount)
      expects_payment_to_be_refunded_on_stripe(payment, partial_refund_amount)
    end

    it 'cancels an order with captured payment' do
      payment = create_captured_payment
      visit_payments_page

      cancel_order

      # https://github.com/solidusio/solidus/blob/ab59d6435239b50db79d73b9a974af057ad56b52/core/app/models/spree/payment_method.rb#L169-L181
      pending "needs to implement try_void method to handle voiding payments on order cancellation"

      expects_page_to_display_successfully_canceled_order_payment(payment)
      expects_payment_to_be_voided_on_stripe(payment)
    end

    it 'cancels an order with authorized payment' do
      payment = create_authorized_payment
      visit_payments_page

      cancel_order

      # https://github.com/solidusio/solidus/blob/ab59d6435239b50db79d73b9a974af057ad56b52/core/app/models/spree/payment_method.rb#L169-L181
      # Note that for this specific case, the test is pending also because there is an issue
      # with locating the user who canceled the order.
      pending "needs to implement try_void method to handle voiding payments on order cancellation"

      expects_page_to_display_successfully_canceled_order_payment(payment)
      expects_payment_to_be_voided_on_stripe(payment)
    end
  end

  context 'with failed payment operations' do
    it 'fails to capture a payment due to incomplete 3D Secure authentication' do
      payment = create_authorized_payment(card_number: '4000000000003220')
      visit_payments_page

      capture_payment

      expects_page_to_display_capture_fail_message(payment,
        'This PaymentIntent could not be captured because it has a status of requires_action.')
    end
  end
end
