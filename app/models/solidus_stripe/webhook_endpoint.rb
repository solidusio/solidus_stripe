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
  class WebhookEndpoint < ::Spree::Base
    belongs_to :payment_method,
      class_name: 'SolidusStripe::PaymentMethod'

    # @api private
    def self.generate_slug
      SecureRandom.hex(16).then do |slug|
        exists?(slug: slug) ? generate_slug : slug
      end
    end

    # Finds the payment method associated with the given slug.
    #
    # @param slug [String]
    # @raise [ActiveRecord::RecordNotFound] if no payment method is found
    # @return [SolidusStripe::PaymentMethod]
    def self.payment_method(slug)
      find_by!(slug: slug).payment_method
    end
  end
end
