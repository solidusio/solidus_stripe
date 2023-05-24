# frozen_string_literal: true

create_file "public/robots.txt"
bundle_command "add solidus_frontend --github solidusio/solidus_frontend --branch #{ENV['SOLIDUS_BRANCH'] || 'main'}"
generate "solidus_frontend:install --auto-accept"
empty_directory 'lib/generators/solidus_frontend/install'

create_file 'lib/generators/solidus_frontend/install/install_generator.rb', <<-CODE
  puts "SolidusFrontend::Generators::InstallGenerator was disabled."
  module SolidusFrontend
    module Generators
      class InstallGenerator < Rails::Generators::Base
        class_option :auto_accept, type: :boolean, default: false
      end
    end
  end
CODE
