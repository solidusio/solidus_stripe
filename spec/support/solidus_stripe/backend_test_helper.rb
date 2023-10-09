# frozen_string_literal: true

module SolidusStripe::BackendTestHelper
  def create_payment_method(setup_future_usage: 'off_session', auto_capture: false)
    @payment_method = create(
      :solidus_stripe_payment_method,
      preferred_setup_future_usage: setup_future_usage,
      auto_capture: auto_capture
    )
  end

  def payment_method
    # Memoize the payment method id to avoid fetching it multiple times
    @payment_method ||= SolidusStripe::PaymentMethod.first || create_payment_method
  end

  def order
    @order ||= create(:completed_order_with_totals, line_items_price: 50)
  end

  def last_valid_payment
    order.payments.valid.last
  end

  # Stripe-related helper methods for creating and fetching Stripe objects

  def create_stripe_payment_method(card_number)
    payment_method.gateway.request do
      Stripe::PaymentMethod.create({
        type: 'card',
        card: {
          number: card_number,
          exp_month: 12,
          exp_year: (Time.zone.now.year + 1),
          cvc: '123',
        },
      })
    end
  end

  def create_stripe_payment_intent(stripe_payment_method_id)
    payment_method.gateway.request do
      Stripe::PaymentIntent.create(
        amount: (order.outstanding_balance * 100).to_i,
        capture_method: 'manual',
        confirm: true,
        currency: 'usd',
        payment_method: stripe_payment_method_id
      )
    end
  end

  def fetch_stripe_refund(payment)
    payment_method.gateway.request do
      Stripe::Refund.list(payment_intent: payment.response_code).data.first
    end
  end

  def fetch_stripe_payment_intent(payment)
    payment_method.gateway.request do
      Stripe::PaymentIntent.retrieve(payment.response_code)
    end
  end

  # Navigation helper methods for interacting with the admin panel

  def visit_payments_page
    visit "/admin/orders/#{order.number}/payments"
  end

  def visit_payment_page(payment)
    visit_payments_page
    click_on_payment(payment)
  end

  def click_on_payment(payment)
    payment_number_link = find_link(payment.number)
    page.current_window.resize_to(1200, 800)
    scroll_to payment_number_link
    payment_number_link.click
  end

  # Action helper methods for performing operations on payments

  def create_authorized_payment(opts = {})
    stripe_payment_method = create_stripe_payment_method(opts[:card_number] || '4242424242424242')
    stripe_payment_intent = create_stripe_payment_intent(stripe_payment_method.id)

    create(:solidus_stripe_payment,
      :authorized,
      order: order,
      response_code: stripe_payment_intent.id,
      stripe_payment_method_id: stripe_payment_method.id,
      payment_method: payment_method)
  end

  def create_captured_payment(card_number: '4242424242424242')
    payment = create_authorized_payment(card_number: card_number)
    payment.capture!
    payment
  end

  def create_valid_payment_source
    stripe_payment_method = create_stripe_payment_method('4242424242424242')
    SolidusStripe::PaymentSource.create!(
      stripe_payment_method_id: stripe_payment_method.id,
      payment_method_id: payment_method.id
    )
  end

  def create_order_with_existing_payment_source
    payment_source = create_valid_payment_source
    @order = create(:order_with_line_items, line_items_price: 50)
    order.user.wallet.add(payment_source)
  end

  def complete_order_with_existing_payment_source
    visit_payments_page
    click_on "Continue"
    page.current_window.resize_to(1200, 800)
    click_on "Confirm"
    click_on "Complete Order"
  end

  def refund_payment
    refund_reason = create :refund_reason
    click_icon(:"mail-reply") # Refund icon style reference in solidus_backend
    within '.new_refund' do
      select refund_reason.name, from: 'Reason'
      click_button 'Refund'
    end
  end

  def partially_refund_payment(refund_reason, amount)
    click_icon(:"mail-reply") # Refund icon style reference in solidus_backend
    within '.new_refund' do
      select refund_reason.name, from: 'Reason'
      fill_in 'Amount', with: amount
      click_button 'Refund'
    end
  end

  def capture_partial_payment_amount(payment, amount)
    within_row(1) do
      click_icon(:edit)
      fill_in('amount', with: amount)
      click_icon(:ok)
      expect(page).to have_selector('td.amount span', text: amount.to_money.format)
      expect(payment.reload.amount).to eq(amount)
    end

    capture_payment
  end

  def void_payment
    click_icon(:void)
  end

  def capture_payment
    click_icon(:capture)
  end

  def cancel_order
    visit "/admin/orders/#{order.number}/edit"
    accept_alert do
      click_on 'Cancel'
    end
  end

  # Helper methods for checking expected outcomes and states

  def expects_page_to_display_log_messages(log_messages = [])
    expect(page).to have_content('Log Entries')
    log_messages.each do |log_message|
      expect(page).to have_content(log_message)
    end
  end

  def expects_payment_to_be_refunded_on_stripe(payment, amount)
    stripe_refund = fetch_stripe_refund(payment)
    expect(stripe_refund.amount).to eq(amount * 100)
  end

  def expects_payment_to_be_voided_on_stripe(payment)
    stripe_payment_intent = fetch_stripe_payment_intent(payment)
    expect(stripe_payment_intent.status).to eq('canceled')
  end

  def expects_payment_to_have_correct_capture_amount_on_stripe(payment, amount)
    stripe_payment_intent = fetch_stripe_payment_intent(payment)
    expect(stripe_payment_intent.amount_received).to eq(amount.to_money.fractional)
  end
end
