# frozen-string-literal: true

require "solidus_stripe/seeds"

# rubocop:disable Rails/Output
puts "Creating refund reason for Stripe refunds"
SolidusStripe::Seeds.refund_reasons
# rubocop:enable Rails/Output
