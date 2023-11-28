# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe 'SolidusStripe Checkout', :js do
  include SolidusStripe::CheckoutTestHelper

  # To learn more about setup_future_usage in different contexts with Stripe Payment Intents:
  # https://stripe.com/docs/payments/payment-intents#future-usage
  ['', 'on_session', 'off_session'].each do |setup_future_usage|
    context "with Stripe Payment Intents and setup_future_usage=#{setup_future_usage}" do
      before { create_payment_method(setup_future_usage: setup_future_usage) }

      it 'creates a payment intent and successfully processes payment' do
        successfully_creates_a_payment_intent(user: create(:user))

        capture_last_valid_payment
      end

      context 'with a guest user' do
        it 'creates a payment intent and successfully processes payment' do
          successfully_creates_a_payment_intent

          capture_last_valid_payment
        end
      end
    end
  end

  context 'when auto-capture is enabled' do
    it 'creates a payment intent and automatically processes payment' do
      create_payment_method(auto_capture: true)

      successfully_creates_a_payment_intent(user: create(:user), auto_capture: true)
    end
  end

  context 'with a registered user' do
    it 'successfully processes payment using available store credits' do
      create(:store_credit_payment_method)
      create_payment_method
      user = create(:user)
      store_credit_amount = 5
      create(:store_credit, user: user, amount: store_credit_amount)

      successfully_creates_a_payment_intent(user: user)

      expects_to_have_specific_authorized_amount_on_stripe(current_order.total - store_credit_amount)
    end

    ['on_session', 'off_session'].each do |setup_future_usage|
      context "when setup_future_usage is set with '#{setup_future_usage}'" do
        before { create_payment_method(setup_future_usage: setup_future_usage) }

        it "successfully reuses a previously saved card from the user's wallet" do
          user = create(:user)
          successfully_creates_a_payment_intent(user: user)

          visit_payment_step(user: user)
          find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
          submit_payment
          complete_order
          payment_intent_is_created_with_required_capture
          capture_last_valid_payment
        end
      end
    end

    context 'when setup_future_usage is not set' do
      it 'requires the user to enter their payment information for each new transaction' do
        create_payment_method(setup_future_usage: '')
        user = create(:user)

        successfully_creates_a_payment_intent(user: user)

        visit_payment_step(user: user)

        expects_page_to_not_display_wallet_payment_sources
      end
    end
  end

  context 'with non-card Stripe payment methods' do
    before do
      stub_spree_preferences(currency: 'EUR')
      create_payment_method(setup_future_usage: 'off_session', auto_capture: true)
    end

    it 'creates a payment intent and successfully processes sepa_debit payment' do
      visit_payment_step(user: create(:user))
      choose_new_stripe_payment
      choose_stripe_payment_method(payment_method_type: "sepa_debit")
      fills_in_stripe_input 'iban', with: 'DE89370400440532013000'

      submit_payment
      complete_order

      expects_payment_to_be_processing
    end
  end

  context 'with declined cards' do
    it 'reject transactions with cards declined at intent creation or invalid fields and return an appropriate response' do # rubocop:disable Layout/LineLength
      create_payment_method
      visit_payment_step(user: create(:user))
      choose_new_stripe_payment

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
        create_payment_method
        visit_payment_step(user: create(:user))
        choose_new_stripe_payment
        fill_in_stripe_country('United States')

        # This 3D Secure card requires authentication for all transactions,
        # regardless of its setup.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#authentication-and-setup
        fill_stripe_form(number: '4000002760003184')
        submit_payment

        check_terms_of_service
        confirm_order
        authorize_3d_secure_payment(authenticate: false)

        expects_page_and_order_to_be_in_payment_step
        expect(page).to have_content(
          "We are unable to authenticate your payment method. " \
          "Please choose a different payment method and try again.",
          wait: 15
        )

        fill_in_stripe_country('United States')
        clear_stripe_form

        # This test script is using 3D Secure 2 authentication, which must be
        # completed for the payment to be successful.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#three-ds-cards
        fill_stripe_form(number: '4000000000003220')
        submit_payment
        check_terms_of_service
        confirm_order
        authorize_3d_secure_2_payment(authenticate: false)

        expects_page_and_order_to_be_in_payment_step
        expect(page).to have_content(
          "We are unable to authenticate your payment method. " \
          "Please choose a different payment method and try again.",
          wait: 15
        )
      end

      it 'processes the transaction with successful authentication' do
        user = create(:user)

        create_payment_method(setup_future_usage: '')
        visit_payment_step(user: user)
        choose_new_stripe_payment
        fill_in_stripe_country('United States')

        # This 3D Secure card requires authentication for all transactions,
        # regardless of its setup.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#authentication-and-setup
        fill_stripe_form(number: '4000002760003184')
        submit_payment
        check_terms_of_service
        confirm_order
        authorize_3d_secure_payment(authenticate: true)
        expect(page).to have_content('Your order has been processed successfully')
        payment_intent_is_created_with_required_capture

        visit_payment_step(user: user)
        choose_new_stripe_payment
        fill_in_stripe_country('United States')

        # This test script is using 3D Secure 2 authentication, which must be
        # completed for the payment to be successful.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#three-ds-cards
        fill_stripe_form(number: '4000000000003220')
        submit_payment
        check_terms_of_service
        confirm_order
        authorize_3d_secure_2_payment(authenticate: true)
        expect(page).to have_content('Your order has been processed successfully')
        payment_intent_is_created_with_required_capture
      end
    end
  end

  context 'when refreshing the confirmation page' do
    it 'does not create a duplicate payment intent' do
      create_payment_method
      visit_payment_step(user: create(:user))
      choose_new_stripe_payment
      fill_in_stripe_country('United States')
      fill_stripe_form(number: '4000000000003220')
      submit_payment
      expect(page).to have_content('Confirm')
      check_terms_of_service # ensure we're on the confirm page before refreshing
      page.driver.browser.navigate.refresh
      check_terms_of_service
      confirm_order
      authorize_3d_secure_2_payment(authenticate: true)
      expect(page).to have_content('Your order has been processed successfully')
      payment_intent_is_created_with_required_capture
    end
  end
end
