require "simplecov"
SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'solidus_support/extension/feature_helper'

require 'selenium-webdriver'

Capybara.javascript_driver = :selenium_chrome

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

Capybara.server = :webrick

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  FactoryBot.find_definitions
end
