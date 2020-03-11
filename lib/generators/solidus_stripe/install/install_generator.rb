# frozen_string_literal: true

module SolidusStripe
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/frontend/all.js', "//= require spree/frontend/solidus_stripe\n"
      end

      def add_stylesheets
        filename = 'vendor/assets/stylesheets/spree/frontend/all.css'
        if File.file? filename
          inject_into_file filename, " *= require spree/frontend/solidus_stripe\n", before: '*/', verbose: true
        end
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=solidus_stripe'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask('Would you like to run the migrations now? [Y/n]'))
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!' # rubocop:disable Rails/Output
        end
      end

      def populate_seed_data
        return unless options.auto_run_seeds?

        say_status :loading, 'stripe seed data'
        rake('db:seed:solidus_stripe')
      end
    end
  end
end
