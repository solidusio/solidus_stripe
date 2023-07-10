# frozen_string_literal: true

require 'solidus_starter_frontend_spec_helper'

module SolidusStripe::CheckoutTestHelper
  include SolidusStarterFrontend::System::CheckoutHelpers
  def self.included(base)
    base.include Devise::Test::IntegrationHelpers
  end

  # Setup methods
  #
  # These are methods that are used specifically for setting up the
  # environment for testing.

  def assign_guest_token(guest_token)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionDispatch::Cookies::SignedKeyRotatingCookieJar).tap do |allow_cookie_jar|
      # Retrieve all other cookies from the original jar.
      allow_cookie_jar.to receive(:[]).and_call_original
      allow_cookie_jar.to receive(:[]).with(:guest_token).and_return(guest_token)
    end
    # rubocop:enable RSpec/AnyInstance
  end

  def create_payment_method(setup_future_usage: 'off_session', auto_capture: false)
    @payment_method = create(
      :solidus_stripe_payment_method,
      preferred_setup_future_usage: setup_future_usage,
      auto_capture: auto_capture
    )
  end

  def payment_method
    # Memoize the payment method id to avoid fetching it multiple times
    @payment_method ||= SolidusStripe::PaymentMethod.first!
  end

  def current_order
    @current_order ||= Spree::Order.last!
  end

  def last_stripe_payment
    current_order.payments.reorder(id: :desc).find_by(source_type: "SolidusStripe::PaymentSource")
  end

  def capture_last_valid_payment
    payment = current_order.payments.valid.last
    payment.capture!
    expect(payment.payment_method.type).to eq('SolidusStripe::PaymentMethod')
    intent = payment.payment_method.gateway.request do
      Stripe::PaymentIntent.retrieve(payment.response_code)
    end
    expect(intent.status).to eq('succeeded')
  end

  # Stripe form methods
  #
  # These are methods that are used specifically for interacting with
  # the Stripe payment form.

  def fill_stripe_form(
    number: 4242_4242_4242_4242, # rubocop:disable Style/NumericLiterals
    expiry_month: 12,
    expiry_year: Time.current.year + 1,
    date: nil,
    cvc: '123',
    country: 'United States',
    zip: '90210'
  )
    fill_in_stripe_cvc(cvc)
    fill_in_stripe_expiry_date(year: expiry_year, month: expiry_month, date: date)
    fill_in_stripe_card(number)
    fill_in_stripe_country(country)
    fill_in_stripe_zip(zip) if zip # not shown for every country
  end

  def fill_in_stripe_card(number)
    fills_in_stripe_input 'number', with: number
  end

  def fill_in_stripe_expiry_date(year: nil, month: nil, date: nil)
    date ||= begin
      month = month.to_s.rjust(2, '0') unless month.is_a? String
      year = year.to_s[2..3] unless year.is_a? String
      "#{month}#{year}"
    end

    fills_in_stripe_input 'expiry', with: date.to_s[0..3]
  end

  def fill_in_stripe_cvc(cvc)
    fills_in_stripe_input 'cvc', with: cvc.to_s[0..2].to_s
  end

  def fill_in_stripe_country(country_name)
    using_wait_time(10) do
      within_frame(find_stripe_iframe) do
        find(%{select[name="country"]}).select(country_name)
      end
    end
  end

  def fill_in_stripe_zip(zip)
    fills_in_stripe_input 'postalCode', with: zip
  end

  def fills_in_stripe_input(name, with:)
    using_wait_time(10) do
      within_frame(find_stripe_iframe) do
        with.to_s.chars.each { find(%{input[name="#{name}"]}).send_keys(_1) }
      end
    end
  end

  def clear_stripe_form
    %w[number expiry cvc postalCode].each do |name|
      using_wait_time(10) do
        within_frame(find_stripe_iframe) do
          field = find(%{input[name="#{name}"]})
          field.value.length.times { field.send_keys [:backspace] }
        end
      end
    end
  end

  def find_stripe_iframe
    fieldset = find_payment_fieldset(payment_method.id)
    expect(fieldset).to have_css('iframe', wait: 15) # trigger waiting if the frame is not yet there
    fieldset.find("iframe")
  end

  # 3D Secure methods
  #
  # These are methods that are used specifically for handling 3D Secure (3DS) payment
  # authorizations.
  #
  # However, it's important to note that this process may require an additional step,
  # (currently not fully supported), which is indicated by the "next_action" property
  # of the Stripe PaymentIntent object.
  #
  # More information on this property can be found in the Stripe API documentation:
  # PaymentIntent objects : https://stripe.com/docs/api/payment_intents/object#payment_intent_object-next_action

  def authorize_3d_secure_payment(authenticate: true)
    find_frame('body > div > iframe') do
      find_frame('#challengeFrame') do
        find_frame("iframe[name='acsFrame']") do
          click_on authenticate ? 'Complete authentication' : 'Fail authentication'
        end
      end
    end
  end

  def authorize_3d_secure_2_payment(authenticate: true)
    find_frame('body > div > iframe') do
      find_frame('#challengeFrame') do
        click_on authenticate ? 'Complete' : 'Fail'
      end
    end
  end

  def find_frame(selector, &block)
    using_wait_time(15) do
      frame = find(selector)
      within_frame(frame, &block)
    end
  end

  # Checkout methods
  #
  # These are methods that are used specifically for interacting with
  # the checkout process.

  def visit_payment_step(user: nil)
    @current_order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: user)

    if user
      sign_in current_order.user
    else
      assign_guest_token current_order.guest_token
    end

    visit '/checkout/payment'
  end

  def choose_new_stripe_payment
    choose(option: payment_method.id)
  end

  def choose_stripe_payment_method(payment_method_type: 'card')
    using_wait_time(10) do
      within_frame(find_stripe_iframe) do
        # Stripe doesn't display payment methods in the same order.
        # The payment method order is based on the most used in that
        # context (and other parameters).
        # For this reason, if the payment method tab is not visible,
        # it will be selected from the dedicated additional Stripe
        # payment methods "select" rendered in the Stripe payment form.
        #
        # https://stripe.com/docs/payments/customize-payment-element#payment-method-order
        if has_css?("##{payment_method_type}-tab")
          find("##{payment_method_type}-tab").click
        else
          find(
            ".p-AdditionalPaymentMethods-menu option[value='#{payment_method_type}']"
          ).select_option
        end
      end
    end
  end

  def submit_payment
    click_button("Save and Continue")
  end

  def check_terms_of_service
    expect(page).to have_content("Agree to Terms of Service")
    check "Agree to Terms of Service"
  end

  def confirm_order
    click_button("Place Order")
  end

  def complete_order
    check_terms_of_service
    confirm_order
    expect(page).to have_content('Your order has been processed successfully')
  end

  def expects_page_and_order_to_be_in_payment_step
    expect(page).to have_current_path('/checkout/payment')
    expect(current_order.state).to eq('payment')
  end

  def expects_payment_to_be_failed
    expect(last_stripe_payment.state).to eq('failed')
  end

  def expects_payment_to_be_processing
    expect(last_stripe_payment.state).to eq('processing')
  end

  def expects_page_to_not_display_wallet_payment_sources
    expect(page).to have_no_selector("[name='order[wallet_payment_source_id]']")
  end

  def expects_to_have_specific_authorized_amount_on_stripe(amount)
    stripe_payment_intent = payment_method.gateway.request do
      Stripe::PaymentIntent.retrieve(last_stripe_payment.response_code)
    end
    expect(stripe_payment_intent.amount).to eq(amount * 100)
  end

  # Test methods
  #
  # These are methods that are used specifically for testing the Stripe
  # checkout process.

  def payment_intent_is_created_with_required_capture
    intent = SolidusStripe::PaymentIntent.where(
      payment_method: payment_method,
      order: current_order
    ).last.stripe_intent
    expect(intent.status).to eq('requires_capture')
  end

  def payment_intent_is_created_and_successfully_captured
    order = Spree::Order.last
    intent = SolidusStripe::PaymentIntent.where(
      payment_method: payment_method,
      order: order
    ).last.stripe_intent
    expect(intent.status).to eq('succeeded')
  end

  def payment_intent_is_created_with_required_action
    intent = SolidusStripe::PaymentIntent.where(
      payment_method: payment_method,
      order: current_order
    ).last.stripe_intent
    expect(intent.status).to eq('requires_action')
  end

  def invalid_data_are_notified
    fill_in_stripe_country('United States')

    [
      [{ number: '4242424242424241' }, 'Your card number is invalid'],  # incorrect_number
      [{ date: '1110' }, "Your card's expiration year is in the past"], # invalid_expiry_year
      [{ cvc: 99 }, "Your card's security code is incomplete"]          # invalid_cvc
    ].each do |args, text|
      clear_stripe_form
      fill_stripe_form(**args)
      submit_payment
      using_wait_time(10) do
        within_frame(find_stripe_iframe) do
          expect(page).to have_content(text)
        end
      end
    end
  end

  def incomplete_cards_are_notified
    # In order to have a complete Stripe form,
    # it's essential to have a Postal Code field that will only be displayed
    # when the user selects United States as their country.
    fill_in_stripe_country('United States')

    clear_stripe_form
    submit_payment
    [
      "Your card number is incomplete",
      "Your card's expiration date is incomplete",
      "Your card's security code is incomplete",
      "Your postal code is incomplete"
    ].each do |text|
      within_frame(find_stripe_iframe) do
        expect(page).to have_content(text)
      end
    end
  end

  def declined_cards_at_intent_creation_are_notified
    [
      # Decline codes
      # https://stripe.com/docs/declines/codes
      ['4000000000000002', 'Your card has been declined.'],                  # Generic decline
      ['4000000000009995', 'Your card has insufficient funds.'],             # Insufficient funds decline
      ['4000000000009987', 'Your card has been declined.'],                  # Lost card decline
      ['4000000000009979', 'Your card has been declined.'],                  # Stolen card decline
      ['4000000000000069', 'Your card has expired.'],                        # Expired card decline
      ['4000000000000127', "Your card's security code is incorrect."],       # Incorrect CVC decline
      ['4000000000000119', 'An error occurred while processing your card.'], # Processing error decline

      # Fraudulent cards
      # https://stripe.com/docs/testing#fraud-prevention
      ['4100000000000019', 'Your card has been declined.'],                  # Always blocked
    ].each do |number, text|
      fill_in_stripe_country('United States')
      fill_stripe_form(number: number)
      submit_payment
      check_terms_of_service
      confirm_order
      expect(page).to have_content(text, wait: 15)
    end
  end

  def successfully_creates_a_payment_intent(user: nil, auto_capture: false)
    visit_payment_step(user: user)
    choose_new_stripe_payment
    fill_stripe_form

    submit_payment

    complete_order

    if auto_capture
      payment_intent_is_created_and_successfully_captured
    else
      payment_intent_is_created_with_required_capture
    end
  end
end
