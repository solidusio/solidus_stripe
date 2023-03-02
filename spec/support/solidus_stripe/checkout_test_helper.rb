# frozen_string_literal: true

require 'solidus_starter_frontend_helper'

module SolidusStripe::CheckoutTestHelper
  include SystemHelpers
  def self.included(base)
    base.include Devise::Test::IntegrationHelpers
  end

  def assign_guest_token(guest_token)
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ActionDispatch::Cookies::SignedKeyRotatingCookieJar).tap do |allow_cookie_jar|
      # Retrieve all other cookies from the original jar.
      allow_cookie_jar.to receive(:[]).and_call_original
      allow_cookie_jar.to receive(:[]).with(:guest_token).and_return(guest_token)
    end
    # rubocop:enable RSpec/AnyInstance
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

  # Assumes the presence of a #stripe_payment_method helper
  def find_stripe_iframe
    fieldset = find_payment_fieldset(stripe_payment_method.id)
    expect(fieldset).to have_css('iframe') # trigger waiting if the frame is not yet there
    fieldset.find("iframe")
  end
end
