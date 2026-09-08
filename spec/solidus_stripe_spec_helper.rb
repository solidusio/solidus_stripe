# frozen_string_literal: true

require 'stripe'
require 'solidus_storefront_spec_helper'
require 'vcr'

Dir["#{__dir__}/support/solidus_stripe/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include SolidusStripe::Webhook::RequestHelper, type: :webhook_request

  config.define_derived_metadata do |metadata|
    metadata[:solidus_stripe] = true
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<STRIPE_API_KEY>') { ENV['SOLIDUS_STRIPE_API_KEY'] }
  config.filter_sensitive_data('<STRIPE_PUBLISHABLE_KEY>') { ENV['SOLIDUS_STRIPE_PUBLISHABLE_KEY'] }

  config.register_request_matcher :stripe_uri do |live_request, recorded_request|
    normalize = ->(uri) { uri.to_s.gsub(/\bpm_[A-Za-z0-9]{12,}\b/, 'pm_ID') }

    normalize[live_request.uri] == normalize[recorded_request.uri]
  end

  config.default_cassette_options = {
    match_requests_on: [:method, :stripe_uri],
    allow_playback_repeats: true,
  }
end
