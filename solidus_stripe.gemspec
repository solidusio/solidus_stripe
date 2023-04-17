# frozen_string_literal: true

require_relative 'lib/solidus_stripe/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_stripe'
  spec.version = SolidusStripe::VERSION
  spec.authors = ['Solidus Team']
  spec.email = 'contact@solidus.io'

  spec.summary = 'Stripe Payment Method for Solidus'
  spec.description = 'Stripe Payment Method for Solidus'
  spec.homepage = 'https://github.com/solidusio/solidus_stripe#readme'
  spec.license = 'BSD-3'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio/solidus_stripe'
  spec.metadata['changelog_uri'] = 'https://github.com/solidusio/solidus_stripe/releases'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.0')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'solidus_core', ['>= 3.2', '< 4']
  spec.add_dependency 'solidus_support', '~> 0.8'

  spec.add_dependency 'stripe', '~> 8.0'

  spec.add_development_dependency 'redcarpet' # used by yard
  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
  spec.add_development_dependency 'yard'

  spec.post_install_message = <<~TXT
    ------------------------------------------------------------------------
            ⚠️ **WARNING: `solidus_stripe` & `solidus_frontend** ⚠️
    ------------------------------------------------------------------------

    If you need support for `solidus_frontend` please add `< 5`
    as a version requirement in your gemfile:

    `gem 'solidus_stripe', '< 5'`

    or if your tracking the github version please switch to
    the `v4` branch:

    `gem 'solidus_stripe', github: 'solidusio/solidus_stripe', branch: 'v4'`

    ------------------------------------------------------------------------
  TXT
end
