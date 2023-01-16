# frozen_string_literal: true

SolidusStripe.configure do |config|
  # TODO: Remember to change this with the actual preferences you have implemented!
  # config.sample_preference = 'sample_value'
end

Rails.application.reloader.to_prepare do
  if ENV['SOLIDUS_STRIPE_API_KEY']
    Spree::Config.static_model_preferences.add(
      SolidusStripe::PaymentMethod,
      'stripe_env_credentials',
      api_key: ENV['SOLIDUS_STRIPE_API_KEY'],
      publishable_key: ENV['SOLIDUS_STRIPE_PUBLISHABLE_KEY'],
      test_mode: ENV['SOLIDUS_STRIPE_API_KEY'].start_with?('sk_test_'),
    )
  end
end
