# frozen_string_literal: true

module Spree
  class StripeController < SolidusStripe::IntentsController
    include Core::ControllerHelpers::Order

    def confirm_payment
      Deprecation.warn "please use SolidusStripe::IntentsController#confirm"

      confirm
    end
  end
end
