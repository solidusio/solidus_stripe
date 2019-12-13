# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'solidus_stripe/version'

Gem::Specification.new do |s|
  s.name = 'solidus_stripe'
  s.version = SolidusStripe::VERSION
  s.summary     = "Stripe Payment Method for Solidus"
  s.description = s.summary
  s.required_ruby_version = ">= 2.2"

  s.author       = "Solidus Team"
  s.email        = "contact@solidus.io"
  s.homepage     = "https://solidus.io"
  s.license      = 'BSD-3'

  if s.respond_to?(:metadata)
    s.metadata["homepage_uri"] = s.homepage if s.homepage
    s.metadata["source_code_uri"] = s.homepage if s.homepage
  end

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = "lib"
  s.requirements << "none"

  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.add_dependency 'solidus_core', ['>= 2.3', '< 3']
  s.add_dependency 'solidus_support', '~> 0.4.0'
  # ActiveMerchant v1.58 through v1.59 introduced a breaking change
  # to the stripe gateway.
  #
  # This was resolved in v1.60, but we still need to skip 1.58 & 1.59.
  s.add_dependency "activemerchant", ">= 1.100" # includes "Stripe Payment Intents: Fix fallback for Store"

  s.add_development_dependency 'solidus_dev_support'
end
