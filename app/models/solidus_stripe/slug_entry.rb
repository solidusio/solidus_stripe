# frozen_string_literal: true

module SolidusStripe
  # Represents a webhook endpoint for a {SolidusStripe::PaymentMethod}.
  #
  # A Stripe webhook endpoint is a URL that Stripe will send events to. A store
  # could have multiple Stripe payment methods (e.g., a marketplace), so we need
  # to differentiate which one a webhook request targets.
  #
  # This model associates a slug with a payment method. The slug is appended
  # to the endpoint URL (`.../webhooks/:slug`) so that we can fetch the
  # correct payment method from the database and bind it to the generated
  # `Spree::Bus` event.
  #
  # We use a slug instead of the payment method ID to be resilient to
  # database changes and to avoid guessing about valid endpoint URLs.
  class SlugEntry < ::Spree::Base
    belongs_to :payment_method, class_name: 'SolidusStripe::PaymentMethod'
  end
end
