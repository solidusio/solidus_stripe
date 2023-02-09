# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe "Checkout with Stripe", :vcr do
  it "completes as a registered user" do
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery)

    user = create(:user)
    visit '/'
    click_link 'Login'
    fill_in 'spree_user[email]', with: user.email
    fill_in 'spree_user[password]', with: 'secret'
    click_button 'Login'
    order.user = user
    order.recalculate

    allow_any_instance_of( # rubocop:disable RSpec/AnyInstance
      CheckoutsController
    ).to receive_messages(
      current_order: order, try_spree_current_user: user
    )
    payment_method = create(:stripe_payment_method)
    payment_intent = Stripe::PaymentIntent.construct_from(
      id: 'pi_test_1234567890',
      client_secret: 'cs_test_1234567890',
    )
    allow(Stripe::PaymentIntent).to receive(:create).with({
      amount: 20_00,
      currency: 'USD',
      capture_method: 'manual',
    }).and_return(payment_intent, instance_double(Stripe::StripeResponse))
    allow(Stripe::PaymentIntent).to receive(:retrieve).with(payment_intent.id).and_return(payment_intent)
    # rubocop:disable RSpec/AnyInstance, RSpec/MessageChain
    allow_any_instance_of(CheckoutsController).to receive_message_chain(
      :cookies,
      :signed,
    ).and_return(guest_token: order.guest_token)
    # rubocop:enable RSpec/AnyInstance, RSpec/MessageChain

    visit '/checkout/payment'
    choose(option: payment_method.id)
    click_button("Save and Continue")
    click_button("Place Order")
  end

  it "completes as a guest" do
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: nil)
    visit '/'

    allow_any_instance_of( # rubocop:disable RSpec/AnyInstance
      CheckoutsController
    ).to receive_messages(
      current_order: order
    )
    payment_method = create(:stripe_payment_method)
    payment_intent = Stripe::PaymentIntent.construct_from(
      id: 'pi_test_1234567890',
      client_secret: 'cs_test_1234567890',
    )
    allow(Stripe::PaymentIntent).to receive(:create).with({
      amount: 20_00,
      currency: 'USD',
      capture_method: 'manual',
    }).and_return(payment_intent, instance_double(Stripe::StripeResponse))
    allow(Stripe::PaymentIntent).to receive(:retrieve).with(payment_intent.id).and_return(payment_intent)
    # rubocop:disable RSpec/AnyInstance, RSpec/MessageChain
    allow_any_instance_of(CheckoutsController).to receive_message_chain(
      :cookies,
      :signed,
    ).and_return(guest_token: order.guest_token)
    # rubocop:enable RSpec/AnyInstance, RSpec/MessageChain

    visit '/checkout/payment'
    choose(option: payment_method.id)
    click_button("Save and Continue")
    click_button("Place Order")
  end
end
