source "https://rubygems.org"

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch

group :test do
  if branch == 'master' || branch >= "v2.0"
    gem "rails-controller-testing"
  end

  if branch < "v2.5"
    gem 'factory_bot', '4.10.0'
  else
    gem 'factory_bot', '> 4.10.0'
  end

  gem 'chromedriver-helper' if ENV['CI']
end

gem 'pg'
gem 'mysql2'

group :development, :test do
  gem "pry-rails"
  gem "ffaker"
end

gemspec
