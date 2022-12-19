# frozen_string_literal: true

module SolidusStripe
  module Generators
    class InstallGenerator < Rails::Generators::Base
      class_option :migrate, type: :boolean, default: true
      class_option :backend, type: :boolean, default: true
      class_option :starter_frontend, type: :boolean, default: true

      # This is only used to run all-specs during development and CI,  regular installation limits
      # installed specs to frontend, which are the ones related to code copied to the target application.
      class_option :specs, type: :string, enum: %w[all frontend], default: 'frontend', hide: true

      source_root File.expand_path('templates', __dir__)

      def install_solidus_core_support
        directory 'config/initializers', 'config/initializers'
        rake 'railties:install:migrations FROM=solidus_stripe'
        run 'bin/rails db:migrate' if options[:migrate]
        route "mount SolidusStripe::Engine, at: '/solidus_stripe'"
      end

      def install_solidus_backend_support
        support_code_for(:backend) do
          append_file(
            'vendor/assets/javascripts/spree/backend/all.js',
            "//= require spree/backend/solidus_stripe\n"
          )
          inject_into_file(
            'vendor/assets/stylesheets/spree/backend/all.css',
            " *= require spree/backend/solidus_stripe\n",
            before: %r{\*/},
            verbose: true,
          )
        end
      end

      def install_solidus_starter_frontend_support
        support_code_for(:starter_frontend) do
          directory 'app', 'app'
          append_file(
            'app/assets/javascripts/solidus_starter_frontend.js',
            "//= require spree/frontend/solidus_stripe\n"
          )
          inject_into_file(
            'app/assets/stylesheets/solidus_starter_frontend.css',
            " *= require spree/frontend/solidus_stripe\n",
            before: %r{\*/},
            verbose: true,
          )

          spec_paths =
            case options[:specs]
            when 'all' then %w[spec]
            when 'frontend'
              %w[
                spec/solidus_stripe_spec_helper.rb
                spec/system/frontend
                spec/support
              ]
            end

          spec_paths.each do |path|
            if engine.root.join(path).directory?
              directory engine.root.join(path), path
            else
              template engine.root.join(path), path
            end
          end
        end
      end

      private

      def support_code_for(component_name, &block)
        if options[component_name]
          say_status :install, "[#{engine.engine_name}] solidus_#{component_name}", :blue
          shell.indent(&block)
        else
          say_status :skip, "[#{engine.engine_name}] solidus_#{component_name}", :blue
        end
      end

      def engine
        SolidusStripe::Engine
      end
    end
  end
end
