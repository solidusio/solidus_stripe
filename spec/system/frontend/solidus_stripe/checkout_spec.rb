# frozen_string_literal: true

require 'solidus_stripe_spec_helper'

RSpec.describe 'SolidusStripe Checkout', :js do
  include SolidusStripe::CheckoutTestHelper

  # To learn more about setup_future_usage in different contexts with Stripe Setup Intents:
  # https://stripe.com/docs/payments/setup-intents#increasing-success-rate-by-specifying-usage
  ['on_session', 'off_session'].each do |setup_future_usage|
    context "with Stripe Setup Intents and setup_future_usage=#{setup_future_usage}" do
      before do
        creates_payment_method(
          intents_flow: 'setup',
          setup_future_usage: setup_future_usage
        )
      end

      context 'with a registered user' do
        it 'creates a setup intent and successfully processes payment' do
          successfully_creates_a_setup_intent(user: create(:user))
          completes_order
          payment_intent_is_created_with_required_capture
          captures_last_valid_payment
        end

        it "successfully reuses a previously saved card from the user's wallet" do
          user = create(:user)

          successfully_creates_a_setup_intent(user: user)
          completes_order
          payment_intent_is_created_with_required_capture
          captures_last_valid_payment

          visits_payment_step(user: user)
          find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
          submits_payment
          completes_order
          payment_intent_is_created_with_required_capture
          captures_last_valid_payment
        end

        it 'creates a setup intent with a 3D Secure card and successfully processes payment' do
          visits_payment_step(user: create(:user))
          chooses_new_stripe_payment

          # Fill in the Stripe payment form with a 3D Secure card
          # This card requires authentication on all transactions,
          # regardless of how the card is set up.
          # See https://stripe.com/docs/testing#authentication-and-setup for more information on this card.
          fills_stripe_form(number: '4000002760003184')

          # Submit the payment form and authorize the 3D Secure payment
          submits_payment
          authorizes_3d_secure_payment

          # Expect the setup intent to be created successfully and complete the order
          setup_intent_is_created_successfully
          completes_order

          # Note that, in case of a Setup Intent, even if it is authorized, the payment intent
          # cannot be captured because a required action is needed most of the times.
          payment_intent_is_created_with_required_action

          # A solution needs to be implemented to handle the required action for these cards.
          pending 'These cards cannot be reused as the required action is not handled'

          payment_intent_is_created_with_required_capture
          captures_last_valid_payment
        end
      end

      context 'with a guest user' do
        it 'creates a setup intent and successfully processes payment' do
          successfully_creates_a_setup_intent
          completes_order
          payment_intent_is_created_with_required_capture
          captures_last_valid_payment
        end
      end
    end
  end

  # To learn more about setup_future_usage in different contexts with Stripe Payment Intents:
  # https://stripe.com/docs/payments/payment-intents#future-usage
  ['', 'on_session', 'off_session'].each do |setup_future_usage|
    context "with Stripe Payment Intents and setup_future_usage=#{setup_future_usage}" do
      let(:skip_confirm_step) { true }

      before do
        creates_payment_method(
          intents_flow: 'payment',
          setup_future_usage: setup_future_usage,
          skip_confirmation: skip_confirm_step
        )
      end

      context 'with a registered user and skip_confirmation_for_payment_intent = true' do
        it 'creates a payment intent and successfully processes payment' do
          successfully_creates_a_payment_intent(user: create(:user))

          captures_last_valid_payment
        end

        it 'creates a payment intent and successfully processes payment with 3d secure card' do
          visits_payment_step(user: create(:user))
          chooses_new_stripe_payment

          # Fill in the Stripe payment form with a 3D Secure card
          # This card requires authentication on all transactions, regardless
          # of how the card is set up.
          # See https://stripe.com/docs/testing#authentication-and-setup for more information on this card.
          fills_stripe_form(number: '4000002760003184')

          # Submit the payment form and authorize the 3D Secure payment
          checks_terms_of_service
          submits_payment
          authorizes_3d_secure_payment
          expect(page).to have_content('Your order has been processed successfully')
          payment_intent_is_created_with_required_capture

          captures_last_valid_payment
        end

        # Payment sources that are not specified for future usage cannot be
        # reused and are not added to the user's wallet
        if setup_future_usage.present?
          it "successfully reuses a previously saved card from the user's wallet" do
            user = create(:user)

            successfully_creates_a_payment_intent(user: user)
            captures_last_valid_payment

            visits_payment_step(user: user)
            find_existing_payment_radio(user.wallet_payment_sources.first.id).choose
            submits_payment
            checks_terms_of_service
            confirms_order
            expect(page).to have_content('Your order has been processed successfully')
            payment_intent_is_created_with_required_capture
            captures_last_valid_payment
          end
        end
      end

      context 'with a registered user and skip_confirmation_for_payment_intent = false' do
        let(:skip_confirm_step) { false }

        it 'creates a payment intent and successfully processes payment' do
          successfully_creates_a_payment_intent(user: create(:user))

          captures_last_valid_payment
        end
      end

      context 'with a guest user' do
        it 'creates a payment intent and successfully processes payment' do
          successfully_creates_a_payment_intent

          captures_last_valid_payment
        end
      end
    end
  end

  context 'with declined cards' do
    it 'reject transactions with cards declined at intent creation or invalid fields and return an appropriate response' do # rubocop:disable Metrics/LineLength
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

    it 'reject transactions with cards declined at the confirm step and return an appropriate response' do
      creates_payment_method(
        intents_flow: 'setup'
      )
      visits_payment_step(user: create(:user))
      chooses_new_stripe_payment

      declined_cards_at_confirm_are_notified
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
        authorizes_3d_secure_payment(authenticate: false)
        using_wait_time(15) do
          expect(page).to have_content('An unexpected error occurred')
        end

        # This test script is using 3D Secure 2 authentication, which must be
        # completed for the payment to be successful.
        # Please refer to the Stripe documentation for more information:
        # https://stripe.com/docs/testing#three-ds-cards
        clears_stripe_form
        fills_stripe_form(number: '4000000000003220')
        submits_payment
        authorizes_3d_secure_2_payment(authenticate: false)
        using_wait_time(15) do
          expect(page).to have_content('An unexpected error occurred')
        end
      end
    end
  end
end
