# frozen_string_literal: true

source 'https://rubygems.org'

branch = ENV.fetch("SOLIDUS_BRANCH", "main")
if ENV["SOLIDUS_PATH"]
  gem "solidus", path: ENV["SOLIDUS_PATH"]
else
  gem "solidus", github: "solidusio/solidus", branch: branch
end

rails_version = ENV.fetch("RAILS_VERSION", "8.0")
gem "rails", "~> #{rails_version}"

case ENV.fetch("DB", nil)
when "mysql"
  gem "mysql2"
when "postgresql"
  gem "pg"
else
  gem "sqlite3", (rails_version < "7.2") ? "~> 1.4" : "~> 2.0"
end

if branch <= "v4.5"
  gem "state_machines", "<= 0.6"
end

# Those are due to the "stdlib gemification" that's
# happening between versions of ruby.
gem 'stringio'
gem 'timeout'

gem 'listen'

gem 'rspec_junit_formatter', require: false

gemspec
