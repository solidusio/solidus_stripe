# frozen_string_literal: true

module SolidusStripe
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :migrate, type: :boolean, default: true
      class_option :auto_run_migrations, type: :boolean, default: false
      class_option :auto_run_seeds, type: :boolean, default: false

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
        if options.migrate? && running_migrations?
          run 'bundle exec rake db:migrate'
        else
          puts "Skiping rake db:migrate, don't forget to run it!"
        end
      end

      def populate_seed_data
        return unless options.auto_run_seeds?

        say_status :loading, 'stripe seed data'
        rake('db:seed:solidus_stripe')
      end

      private

      def running_migrations?
        options.auto_run_migrations? || begin
          response = ask 'Would you like to run the migrations now? [Y/n]'
          ['', 'y'].include? response.downcase
        end
      end
    end
  end
end
