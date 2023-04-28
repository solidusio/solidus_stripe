# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe 'SolidusStripe Orders Payments', :js do
  include SolidusStripe::BackendTestHelper
  include Devise::Test::IntegrationHelpers
  stub_authorization!

  let(:user) { create(:admin_user) }

  context 'with successful payment operations' do
    it 'navigates to the payments page' do
      payment = create_authorized_payment
      visit_payments_page

      click_on 'Payments'
      expect(page).to have_content(payment.number)
    end

    it 'displays log entries for a payment' do
      payment = create(:solidus_stripe_payment, :captured, order: order, payment_method: payment_method)

      visit_payment_page(payment)

      expects_page_to_display_log_messages(["PaymentIntent was confirmed and captured successfully"])
    end

    it 'successfully captures an authorized payment' do
      payment = create_authorized_payment
      visit_payments_page

      capture_payment

      expect(page).to have_content('Payment Updated')
      expect(payment.reload.state).to eq('completed')
      expect(payment.capture_events.first.amount).to eq(payment.amount)
      expects_payment_to_have_correct_capture_amount_on_stripe(payment, payment.amount)
    end

    it 'successfully captures a partial amount of an authorized payment' do
      payment = create_authorized_payment
      partial_capture_amount = payment.amount - 10

      visit_payments_page

      capture_partial_payment_amount(payment, partial_capture_amount)

      expect(page).to have_content('Payment Updated')
      expect(payment.reload.state).to eq('completed')
      expect(payment.capture_events.first.amount).to eq(payment.amount)
      expects_payment_to_have_correct_capture_amount_on_stripe(payment, partial_capture_amount)
    end

    it 'voids a payment from an order' do
      payment = create_authorized_payment
      visit_payments_page

      void_payment

      expect(page).to have_content('Payment Updated')
      expect(payment.reload.state).to eq('void')
      expects_payment_to_be_voided_on_stripe(payment)
    end

    it 'refunds a payment from an order' do
      payment = create_captured_payment
      visit_payments_page

      refund_payment

      expect(page).to have_content('Refund has been successfully created!')
      expect(payment).to be_fully_refunded
      expects_payment_to_be_refunded_on_stripe(payment, payment.amount)
    end

    it 'partially refunds a payment from an order' do
      payment = create_captured_payment
      visit_payments_page

      refund_reason = create(:refund_reason)
      partial_refund_amount = 25
      partially_refund_payment(refund_reason, partial_refund_amount)

      expect(page).to have_content('Refund has been successfully created!')
      expect(payment.reload.state).to eq('completed')
      expect(payment.refunds.first.amount).to eq(partial_refund_amount)
      expects_payment_to_be_refunded_on_stripe(payment, partial_refund_amount)
    end

    it 'cancels an order with captured payment' do
      payment = create_captured_payment

      sign_in user
      visit_payments_page

      cancel_order

      expect(page).to have_content('Order canceled')
      expect(payment.reload.state).to eq('completed')
      expects_payment_to_be_refunded_on_stripe(payment, payment.amount)
    end

    it 'cancels an order with authorized payment' do
      payment = create_authorized_payment

      sign_in user
      visit_payments_page

      cancel_order

      expect(page).to have_content('Order canceled')
      expect(payment.reload.state).to eq('void')
      expects_payment_to_be_voided_on_stripe(payment)
    end

    it 'creates new authorized payment and captures it with existing source successfully' do
      create_payment_method
      create_order_with_existing_payment_source
      complete_order_with_existing_payment_source
      visit_payments_page
      capture_payment
      payment = last_valid_payment

      expect(page).to have_content('Payment Updated')
      expect(payment.reload.state).to eq('completed')
      expect(payment.capture_events.first.amount).to eq(payment.amount)
      expects_payment_to_have_correct_capture_amount_on_stripe(payment, payment.amount)
    end
  end

  context 'with failed payment operations' do
    it 'fails to capture a payment due to incomplete 3D Secure authentication' do
      payment = create_authorized_payment(card_number: '4000000000003220')
      visit_payments_page

      capture_payment

      expect(page).to have_content(
        'This PaymentIntent could not be captured because it has a status of requires_action.'
      )
      expect(payment.reload.state).to eq('failed')
    end
  end
end
