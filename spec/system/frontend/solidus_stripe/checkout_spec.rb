# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe "Checkout with Stripe", :js do
  include SolidusStripe::CheckoutTestHelper

  it "completes as a registered user" do
    create(:stripe_payment_method)
    visit_payment_step(user: create(:user))
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
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

  it "completes as a guest" do
    create(:stripe_payment_method)
    visit_payment_step(user: nil)
    choose_new_stripe_payment
    fill_stripe_form
    submit_payment
    confirm_order

    order = Spree::Order.last
    expect(Spree::Order.count).to eq(1)
    expect_checkout_completion(order)
    expect_payments_state(order, ['pending'], outstanding: order.total)
    order.payments.first.capture!
    expect_payments_state(order, ['completed'], outstanding: 0)
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
