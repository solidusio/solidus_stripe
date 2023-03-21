# frozen_string_literal: true

require 'solidus_starter_frontend_spec_helper'

module SolidusStripe::CheckoutTestHelper
  include SolidusStarterFrontend::SystemHelpers

  def self.included(base)
    base.include Devise::Test::IntegrationHelpers
  end

  # Setup methods
  #
  # These are methods that are used specifically for setting up the
  # environment for testing.

  def assigns_guest_token(guest_token)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionDispatch::Cookies::SignedKeyRotatingCookieJar).tap do |allow_cookie_jar|
      # Retrieve all other cookies from the original jar.
      allow_cookie_jar.to receive(:[]).and_call_original
      allow_cookie_jar.to receive(:[]).with(:guest_token).and_return(guest_token)
    end
    # rubocop:enable RSpec/AnyInstance
  end

  def creates_payment_method(
    intents_flow: 'setup',
    setup_future_usage: 'off_session',
    skip_confirmation: false
  )
    @payment_method = create(:stripe_payment_method,
      preferred_stripe_intents_flow: intents_flow,
      preferred_setup_future_usage: setup_future_usage,
      preferred_skip_confirmation_for_payment_intent: skip_confirmation)
  end

  def payment_method
    # Memoize the payment method id to avoid fetching it multiple times
    @payment_method ||= SolidusStripe::PaymentMethod.first!
  end

  def captures_last_valid_payment
    payment = Spree::Payment.valid.last
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

  def fills_stripe_form(
    number: 4242_4242_4242_4242, # rubocop:disable Style/NumericLiterals
    expiry_month: 12,
    expiry_year: Time.current.year + 1,
    date: nil,
    cvc: '123',
    country: 'United States',
    zip: '90210'
  )
    fills_in_stripe_cvc(cvc)
    fills_in_stripe_expiry_date(year: expiry_year, month: expiry_month, date: date)
    fills_in_stripe_card(number)
    fills_in_stripe_country(country)
    fills_in_stripe_zip(zip) if zip # not shown for every country
  end

  def fills_in_stripe_card(number)
    fills_in_stripe_input 'number', with: number
  end

  def fills_in_stripe_expiry_date(year: nil, month: nil, date: nil)
    date ||= begin
      month = month.to_s.rjust(2, '0') unless month.is_a? String
      year = year.to_s[2..3] unless year.is_a? String
      "#{month}#{year}"
    end

    fills_in_stripe_input 'expiry', with: date.to_s[0..3]
  end

  def fills_in_stripe_cvc(cvc)
    fills_in_stripe_input 'cvc', with: cvc.to_s[0..2].to_s
  end

  def fills_in_stripe_country(country_name)
    using_wait_time(10) do
      within_frame(finds_stripe_iframe) do
        find(%{select[name="country"]}).select(country_name)
      end
    end
  end

  def fills_in_stripe_zip(zip)
    fills_in_stripe_input 'postalCode', with: zip
  end

  def fills_in_stripe_input(name, with:)
    using_wait_time(10) do
      within_frame(finds_stripe_iframe) do
        with.to_s.chars.each { find(%{input[name="#{name}"]}).send_keys(_1) }
      end
    end
  end

  def clears_stripe_form
    %w[number expiry cvc postalCode].each do |name|
      using_wait_time(10) do
        within_frame(finds_stripe_iframe) do
          field = find(%{input[name="#{name}"]})
          field.value.length.times { field.send_keys [:backspace] }
        end
      end
    end
  end

  def finds_stripe_iframe
    fieldset = find_payment_fieldset(payment_method.id)
    expect(fieldset).to have_css('iframe') # trigger waiting if the frame is not yet there
    fieldset.find("iframe")
  end

  # 3D Secure methods
  #
  # These are methods that are used specifically for handling 3D Secure (3DS) payment
  # authorizations.
  #
  # However, it's important to note that this process may require an additional step,
  # (currently not fully supported), which is indicated by the "next_action" property
  # of the Stripe PaymentIntent or SetupIntent object.
  #
  # More information on this property can be found in the Stripe API documentation:
  # PaymentIntent objects : https://stripe.com/docs/api/payment_intents/object#payment_intent_object-next_action
  # SetupIntent objects   : https://stripe.com/docs/api/setup_intents/object#setup_intent_object-next_action

  def authorizes_3d_secure_payment(authenticate: true)
    finds_frame('body > div > iframe') do
      finds_frame('#challengeFrame') do
        finds_frame("iframe[name='acsFrame']") do
          click_on authenticate ? 'Complete authentication' : 'Fail authentication'
        end
      end
    end
  end

  def authorizes_3d_secure_2_payment(authenticate: true)
    finds_frame('body > div > iframe') do
      finds_frame('#challengeFrame') do
        click_on authenticate ? 'Complete' : 'Fail'
      end
    end
  end

  def finds_frame(selector, &block)
    using_wait_time(15) do
      frame = find(selector)
      within_frame(frame, &block)
    end
  end

  # Checkout methods
  #
  # These are methods that are used specifically for interacting with
  # the checkout process.

  def visits_payment_step(user: nil)
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: user)

    if user
      sign_in order.user
    else
      assigns_guest_token order.guest_token
    end

    visit '/checkout/payment'
  end

  def chooses_new_stripe_payment
    choose(option: payment_method.id)
  end

  def submits_payment
    click_button("Save and Continue")
  end

  def checks_terms_of_service
    expect(page).to have_content("Agree to Terms of Service")
    check "Agree to Terms of Service"
  end

  def confirms_order
    click_button("Place Order")
  end

  def completes_order
    checks_terms_of_service
    if payment_method.skip_confirm_step?
      submits_payment
    else
      confirms_order
    end

    expect(page).to have_content('Your order has been processed successfully')
  end

  # Test methods
  #
  # These are methods that are used specifically for testing the Stripe
  # checkout process.

  def setup_intent_is_created_successfully
    order = Spree::Order.last
    intent = SolidusStripe::SetupIntent.retrieve_stripe_intent(
      payment_method: payment_method,
      order: order
    )
    expect(intent.status).to eq('succeeded')
  end

  def payment_intent_is_created_with_required_capture
    order = Spree::Order.last
    intent = SolidusStripe::PaymentIntent.where(
      payment_method: payment_method,
      order: order
    ).last.stripe_intent
    expect(intent.status).to eq('requires_capture')
  end

  def payment_intent_is_created_with_required_action
    order = Spree::Order.last
    intent = SolidusStripe::PaymentIntent.where(
      payment_method: payment_method,
      order: order
    ).last.stripe_intent
    expect(intent.status).to eq('requires_action')
  end

  def invalid_data_are_notified
    fills_in_stripe_country('United States')

    [
      [{ number: '4242424242424241' }, 'Your card number is invalid'],  # incorrect_number
      [{ date: '1110' }, "Your card's expiration year is in the past"], # invalid_expiry_year
      [{ cvc: 99 }, "Your card's security code is incomplete"]          # invalid_cvc
    ].each do |args, text|
      clears_stripe_form
      fills_stripe_form(**args)
      submits_payment
      using_wait_time(10) do
        within_frame(finds_stripe_iframe) do
          expect(page).to have_content(text)
        end
      end
    end
  end

  def incomplete_cards_are_notified
    # In order to have a complete Stripe form,
    # it's essential to have a Postal Code field that will only be displayed
    # when the user selects United States as their country.
    fills_in_stripe_country('United States')

    clears_stripe_form
    submits_payment
    [
      "Your card number is incomplete",
      "Your card's expiration date is incomplete",
      "Your card's security code is incomplete",
      "Your postal code is incomplete"
    ].each do |text|
      within_frame(finds_stripe_iframe) do
        expect(page).to have_content(text)
      end
    end
  end

  def declined_cards_are_notified
    fills_in_stripe_country('United States')

    [
      ['4000000000000002', 'Your card has been declined'],                   # Generic decline
      ['4000000000009995', 'Your card has insufficient funds'],              # Insufficient funds decline
      ['4000000000009987', 'Your card has been declined'],                   # Lost card decline
      ['4000000000009979', 'Your card has been declined'],                   # Stolen card decline
      ['4000000000000069', 'Your card has expired'],                         # Expired card decline
      ['4000000000000127', "Your card's security code is incorrect"],        # Incorrect CVC decline
      ['4000000000000119', 'An error occurred while processing your card']   # Processing error decline
    ].each do |number, text|
      clears_stripe_form
      fills_stripe_form(number: number)
      submits_payment
      using_wait_time(15) do
        expect(page).to have_content(text)
      end
    end
  end

  def successfully_creates_a_setup_intent(user: nil)
    visits_payment_step(user: user)
    chooses_new_stripe_payment
    fills_stripe_form
    submits_payment
    expect(page).to have_content('Payment succeeded!')
    setup_intent_is_created_successfully
  end

  def successfully_creates_a_payment_intent(user: nil)
    visits_payment_step(user: user)
    chooses_new_stripe_payment
    fills_stripe_form

    unless payment_method.skip_confirm_step?
      submits_payment
      expect(page).to have_content('Payment successfully authorized!')
    end

    completes_order
    payment_intent_is_created_with_required_capture
  end
end
