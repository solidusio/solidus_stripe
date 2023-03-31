# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe 'SolidusStripe Checkout', :js do
  include SolidusStripe::CheckoutTestHelper

  # To learn more about setup_future_usage in different contexts with Stripe Payment Intents:
  # https://stripe.com/docs/payments/payment-intents#future-usage
  ['', 'on_session', 'off_session'].each do |setup_future_usage|
    context "with Stripe Payment Intents and setup_future_usage=#{setup_future_usage}" do
      before { creates_payment_method(setup_future_usage: setup_future_usage) }

      it 'creates a payment intent and successfully processes payment' do
        successfully_creates_a_payment_intent(user: create(:user))

        captures_last_valid_payment
      end

      context 'with a guest user' do
        it 'creates a payment intent and successfully processes payment' do
          successfully_creates_a_payment_intent

          captures_last_valid_payment
        end
      end
    end
  end

  context 'when auto-capture is enabled' do
    it 'creates a payment intent and automatically processes payment' do
      creates_payment_method(auto_capture: true)

      successfully_creates_a_payment_intent(user: create(:user), auto_capture: true)
    end
  end

  context 'with a registered user' do
    ['on_session', 'off_session'].each do |setup_future_usage|
      context "when setup_future_usage is set with '#{setup_future_usage}'" do
        before { creates_payment_method(setup_future_usage: setup_future_usage) }

        it "successfully reuses a previously saved card from the user's wallet" do
          user = create(:user)
          successfully_creates_a_payment_intent(user: user)

          visits_payment_step(user: user)
          find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
          submits_payment
          completes_order
          payment_intent_is_created_with_required_capture
          captures_last_valid_payment
        end
      end
    end

    context 'when setup_future_usage is not set' do
      it 'requires the user to enter their payment information for each new transaction' do
        creates_payment_method(setup_future_usage: '')
        user = create(:user)

        successfully_creates_a_payment_intent(user: user)

        visits_payment_step(user: user)

        expects_page_to_not_display_wallet_payment_sources
      end
    end
  end

  context 'with declined cards' do
    it 'reject transactions with cards declined at intent creation or invalid fields and return an appropriate response' do # rubocop:disable Layout/LineLength
      creates_payment_method
      visits_payment_step(user: create(:user))
      chooses_new_stripe_payment

      # Refer to https://stripe.com/docs/testing#invalid-data for more
      # information on generating test data with invalid values.
      invalid_data_are_notified

      # Generic error field messages that appear when the Stripe form
      # has incomplete data for cards
      incomplete_cards_are_notified

      # Check the Stripe documentation for more information on
      # how to test declined payments:
      # https://stripe.com/docs/testing#declined-payments
      declined_cards_at_intent_creation_are_notified
    end

    context 'with 3D Secure cards' do
      it 'reject transaction with failed authentication and return an appropriate response' do
        creates_payment_method
        visits_payment_step(user: create(:user))
        chooses_new_stripe_payment
        fills_in_stripe_country('United States')

        # This 3D Secure card requires authentication for all transactions,
        # regardless of its setup.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#authentication-and-setup
        fills_stripe_form(number: '4000002760003184')
        submits_payment

        checks_terms_of_service
        confirms_order
        authorizes_3d_secure_payment(authenticate: false)

        moves_order_back_to_payment
        expect(page).to have_content(
          "We are unable to authenticate your payment method. " \
          "Please choose a different payment method and try again.",
          wait: 15
        )

        fills_in_stripe_country('United States')
        clears_stripe_form

        # This test script is using 3D Secure 2 authentication, which must be
        # completed for the payment to be successful.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#three-ds-cards
        fills_stripe_form(number: '4000000000003220')
        submits_payment
        checks_terms_of_service
        confirms_order
        authorizes_3d_secure_2_payment(authenticate: false)

        moves_order_back_to_payment
        expect(page).to have_content(
          "We are unable to authenticate your payment method. " \
          "Please choose a different payment method and try again.",
          wait: 15
        )
      end

      it 'processes the transaction with successful authentication' do
        user = create(:user)

        creates_payment_method(setup_future_usage: '')
        visits_payment_step(user: user)
        chooses_new_stripe_payment
        fills_in_stripe_country('United States')

        # This 3D Secure card requires authentication for all transactions,
        # regardless of its setup.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#authentication-and-setup
        fills_stripe_form(number: '4000002760003184')
        submits_payment
        checks_terms_of_service
        confirms_order
        authorizes_3d_secure_payment(authenticate: true)
        expect(page).to have_content('Your order has been processed successfully')
        payment_intent_is_created_with_required_capture

        visits_payment_step(user: user)
        chooses_new_stripe_payment
        fills_in_stripe_country('United States')

        # This test script is using 3D Secure 2 authentication, which must be
        # completed for the payment to be successful.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#three-ds-cards
        fills_stripe_form(number: '4000000000003220')
        submits_payment
        checks_terms_of_service
        confirms_order
        authorizes_3d_secure_2_payment(authenticate: true)
        expect(page).to have_content('Your order has been processed successfully')
        payment_intent_is_created_with_required_capture
      end
    end
  end
end
