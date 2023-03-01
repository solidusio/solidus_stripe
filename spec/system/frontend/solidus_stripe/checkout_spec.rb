# frozen_string_literal: true

require 'solidus_stripe_spec_helper'
require 'solidus_starter_frontend_helper'

RSpec.describe "Checkout with Stripe", :js do
  include Devise::Test::IntegrationHelpers
  include SystemHelpers

  it "completes as a registered user" do
    payment_method = create(:stripe_payment_method)
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: create(:user))

    sign_in order.user
    visit '/checkout/payment'
    choose(option: payment_method.id)
    fill_stripe_form
    click_button("Save and Continue")
    confirm_and_wait_for_the_success_page
    order.reload

    expect(page).to have_content("Your order has been processed successfully")
    expect(page).to have_content(order.number)
    expect(order).to be_complete
    expect(order).to be_completed
    expect(order.payments.first.amount).to eq(20)
    expect(order.payments.pluck(:state)).to eq(['pending'])
    expect(order.outstanding_balance.to_f).to eq(20)

    order.payments.first.capture!

    expect(order.payments.reload.pluck(:state)).to eq(['completed'])
    expect(order.outstanding_balance.to_f).to eq(0)
  end

  it "completes as a guest" do
    payment_method = create(:stripe_payment_method)
    order = Spree::TestingSupport::OrderWalkthrough.up_to(:delivery, user: nil)
    assign_guest_token order.guest_token

    visit '/checkout/payment'
    choose(option: payment_method.id)
    fill_stripe_form
    click_button("Save and Continue")
    confirm_and_wait_for_the_success_page
    order.reload

    expect(page).to have_content("Your order has been processed successfully")
    expect(page).to have_content(order.number)
    expect(order).to be_complete
    expect(order).to be_completed
    expect(order.payments.first.amount).to eq(20)
    expect(order.payments.pluck(:state)).to eq(['pending'])
    expect(order.outstanding_balance.to_f).to eq(20)

    order.payments.first.capture!

    expect(order.payments.reload.pluck(:state)).to eq(['completed'])
    expect(order.outstanding_balance.to_f).to eq(0)
  end

  private

  def assign_guest_token(guest_token)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionDispatch::Cookies::SignedKeyRotatingCookieJar).tap do |allow_cookie_jar|
      # Retrieve all other cookies from the original jar.
      allow_cookie_jar.to receive(:[]).and_call_original
      allow_cookie_jar.to receive(:[]).with(:guest_token).and_return(guest_token)
    end
    # rubocop:enable RSpec/AnyInstance
  end

  def confirm_and_wait_for_the_success_page
    check "Agree to Terms of Service"
    click_button("Place Order")
    expect(page).to have_content("Your order has been processed successfully")
  end

  def fill_stripe_form(
    number: 4242_4242_4242_4242, # rubocop:disable Style/NumericLiterals
    expiry_month: 12,
    expiry_year: Time.current.year + 1,
    cvc: '123',
    country: 'United States',
    zip: '90210'
  )
    fill_in_stripe_cvc(cvc)
    fill_in_stripe_expiry_date(year: expiry_year, month: expiry_month)
    fill_in_stripe_card(number)
    fill_in_stripe_country(country)
    fill_in_stripe_zip(zip) if zip # not shown for every country
  end

  def fill_in_stripe_card(number)
    fill_in_stripe_input 'number', with: number
  end

  def fill_in_stripe_expiry_date(year: nil, month: nil, date: nil)
    date ||= begin
      month = month.to_s.rjust(2, '0') unless month.is_a? String
      year = year.to_s[2..3] unless year.is_a? String
      "#{month}#{year}"
    end

    fill_in_stripe_input 'expiry', with: date.to_s[0..3]
  end

  def fill_in_stripe_cvc(cvc)
    fill_in_stripe_input 'cvc', with: cvc.to_s[0..2].to_s
  end

  def fill_in_stripe_country(country_name)
    using_wait_time(10) do
      within_frame(find_stripe_iframe) do
        find(%{select[name="country"]}).select(country_name)
      end
    end
  end

  def fill_in_stripe_zip(zip)
    fill_in_stripe_input 'postalCode', with: zip
  end

  def fill_in_stripe_input(name, with:)
    using_wait_time(10) do
      within_frame(find_stripe_iframe) do
        with.to_s.chars.each { find(%{input[name="#{name}"]}).send_keys(_1) }
      end
    end
  end

  def stripe_payment_method
    # Memoize the payment method id to avoid fetching it multiple times
    @stripe_payment_method ||= SolidusStripe::PaymentMethod.first!
  end

  def find_stripe_iframe
    fieldset = find_payment_fieldset(stripe_payment_method.id)
    expect(fieldset).to have_css('iframe') # trigger waiting if the frame is not yet there
    fieldset.find("iframe")
  end
end
