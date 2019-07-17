# frozen_string_literal: true

source "https://rubygems.org"

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch

group :test do
  if branch == 'master' || branch >= "v2.0"
    gem "rails-controller-testing"
  end

  gem 'factory_bot', (branch < 'v2.5' ? '4.10.0' : '> 4.10.0')
end

gem 'pg'
gem 'mysql2'

group :development, :test do
  gem "pry-rails"
  gem "ffaker"
end

gemspec
