# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe "Checkout with Stripe", :js do
  include SolidusStripe::CheckoutTestHelper

  it "completes as a registered user and reuses the payment using setup intents" do
    create(:stripe_payment_method, preferred_stripe_intents_flow: 'setup')
    visit_payment_step(user: create(:user))
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    expect_payments_state(Spree::Order.last, ['checkout'])
    confirm_order

    order = Spree::Order.last
    user = order.user
    payment = order.payments.first
    reusable_source = payment.source

    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'])
    payment.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
    expect(SolidusStripe::PaymentSource.count).to eq(1)
    expect(SolidusStripe::PaymentSource.last.stripe_payment_method_id).to be_present

    # Pay with the newly created wallet source
    visit_payment_step(user: user)
    find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
    submit_payment
    expect_payments_state(Spree::Order.last, ['checkout'])
    confirm_order

    order = Spree::Order.last
    payment = order.payments.valid.first
    expect(Spree::Order.count).to eq(2)
    expect(order.user).to eq(user)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'])
    expect(order.payments.valid.count).to eq(1)
    payment.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
    expect(SolidusStripe::PaymentSource.count).to eq(1)
    expect(SolidusStripe::PaymentSource.last.stripe_payment_method_id).to be_present
    expect(payment.source).to eq(reusable_source)
  end

  it "completes as a guest using setup intents" do
    create(:stripe_payment_method, preferred_stripe_intents_flow: 'setup')
    visit_payment_step(user: nil)
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    expect_payments_state(Spree::Order.last, ['checkout'])
    confirm_order

    order = Spree::Order.last
    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'], outstanding: order.total)
    order.payments.first.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
  end

  it "completes as a registered user using payment intents" do
    create(:stripe_payment_method, preferred_stripe_intents_flow: 'payment')
    visit_payment_step(user: create(:user))
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    expect_payments_state(Spree::Order.last, ['pending'])
    confirm_order

    order = Spree::Order.last
    payment = order.payments.first

    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'])
    payment.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
    expect(SolidusStripe::PaymentSource.count).to eq(1)
    expect(SolidusStripe::PaymentSource.last.stripe_payment_method_id).to be_blank
  end

  it "completes as a guest using payment intents" do
    create(:stripe_payment_method, preferred_stripe_intents_flow: 'payment')
    visit_payment_step(user: nil)
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    expect_payments_state(Spree::Order.last, ['pending'])
    confirm_order

    order = Spree::Order.last
    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'], outstanding: order.total)
    order.payments.first.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
  end

  it "completes as a registered user and reuses the payment using payment intents" do
    # Pay for the first time
    create(:stripe_payment_method, preferred_setup_future_usage: 'off_session', preferred_stripe_intents_flow: 'payment')
    visit_payment_step(user: create(:user))
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    expect_payments_state(Spree::Order.last, ['pending'])
    confirm_order

    order = Spree::Order.last
    user = order.user
    payment = order.payments.first
    reusable_source = payment.source

    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'])
    payment.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
    expect(SolidusStripe::PaymentSource.count).to eq(1)
    expect(reusable_source.stripe_payment_method_id).to be_present

    # Pay with the newly created wallet source
    visit_payment_step(user: user)
    find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
    submit_payment
    expect_payments_state(Spree::Order.last, ['invalid', 'checkout'])
    confirm_order

    order = Spree::Order.last
    payment = order.payments.valid.first
    expect(Spree::Order.count).to eq(2)
    expect(order.user).to eq(user)
    expect_checkout_completion(order)
    expect_payments_state(order, ['invalid', 'pending'])
    expect(order.payments.valid.count).to eq(1)
    payment.capture!
    expect_payments_state(order, ['invalid', 'completed'], outstanding: 0)
    expect(SolidusStripe::PaymentSource.count).to eq(2)
    expect(SolidusStripe::PaymentSource.last.stripe_payment_method_id).not_to be_present
    expect(payment.source).to eq(reusable_source)
  end

  private

  def stripe_payment_method
    # Memoize the payment method id to avoid fetching it multiple times
    @stripe_payment_method ||= SolidusStripe::PaymentMethod.first!
  end

  def visit_payment_step(user: nil)
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: user)

    if user
      sign_in order.user
    else
      assign_guest_token order.guest_token
    end

    visit '/checkout/payment'
  end

  def choose_new_stripe_payment
    choose(option: stripe_payment_method.id)
  end

  def submit_payment
    click_button("Save and Continue")
    expect(page).to have_content("Agree to Terms of Service")
  end

  def confirm_order
    check "Agree to Terms of Service"
    click_button("Place Order")
    expect(page).to have_content("Your order has been processed successfully")
  end

  def expect_checkout_completion(order = Spree::Order.last)
    expect(page).to have_content("Your order has been processed successfully")
    expect(page).to have_content(order.number)
    expect(order).to be_complete
    expect(order).to be_completed
  end

  def expect_payments_state(order, states, outstanding: order.total)
    expect(order.payments.valid.sum(:amount)).to eq(order.total)
    expect(order.payments.reload.pluck(:state)).to eq(states)
    expect(order.outstanding_balance.to_f).to eq(outstanding)
  end
end
