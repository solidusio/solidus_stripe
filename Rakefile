# frozen_string_literal: true

# Don't build a dummy app with solidus_bolt enabled
ENV['SKIP_SOLIDUS_BOLT'] = 'true'

require 'solidus_dev_support/rake_tasks'
SolidusDevSupport::RakeTasks.install

# Override the default dummy app generation task to
# make it compatible with all the supported Solidus versions.
Rake::Task['extension:test_app'].clear
task 'extension:test_app' do # rubocop:disable Rails/RakeEnvironment
  Spree::DummyGeneratorHelper.inject_extension_requirements = true

  require 'solidus_stripe'

  Rails.env = ENV["RAILS_ENV"] = 'test'

  Spree::DummyGenerator.start ["--lib-name=solidus_stripe"]

  # While the dummy app is generated the current directory
  # within ruby is changed to that of the dummy app.
  sh({
    'FRONTEND' => ENV['FRONTEND'] || "#{__dir__}/spec/solidus_frontend_app_template.rb",
  }, [
    'bin/rails',
    'generate',
    'solidus:install',
    Dir.pwd, # use the current dir as Rails.root
    "--auto-accept",
    "--authentication=none",
    "--payment-method=none",
    "--migrate=false",
    "--seed=false",
    "--sample=false",
    "--user-class=Spree::LegacyUser",
  ].shelljoin)

  puts "Setting up dummy database..."
  sh "bin/rails db:environment:set RAILS_ENV=test"
  sh "bin/rails db:drop db:create db:migrate VERBOSE=false RAILS_ENV=test"

  puts 'Running extension installation generator...'
  sh "bin/rails generate solidus_stripe:install --auto-run-migrations"
end

task default: ['extension:specs']
