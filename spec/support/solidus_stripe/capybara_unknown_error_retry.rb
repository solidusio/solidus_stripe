# frozen_string_literal: true

require 'capybara/selenium/driver'

module SolidusStripe
  module CapybaraUnknownErrorRetry
    def invalid_element_errors
      @solidus_stripe_invalid_element_errors ||=
        super + [::Selenium::WebDriver::Error::UnknownError]
    end
  end
end

Capybara::Selenium::Driver.prepend(SolidusStripe::CapybaraUnknownErrorRetry)
