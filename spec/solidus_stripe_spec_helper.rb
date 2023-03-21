# frozen_string_literal: true

require 'stripe'
require 'solidus_starter_frontend_spec_helper'

Dir["#{__dir__}/support/solidus_stripe/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include SolidusStripe::Webhook::RequestHelper, type: :webhook_request
end
