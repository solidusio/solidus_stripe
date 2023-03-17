# frozen_string_literal: true

require 'coverage'
require 'simplecov'

SimpleCov.root File.expand_path(__dir__)

if ENV['CODECOV_TOKEN']
  require 'simplecov-cobertura'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::CoberturaFormatter,
    SimpleCov.formatter,
  ])
else
  warn "Provide a CODECOV_TOKEN environment variable to enable Codecov uploads"
end

def (SimpleCov::ResultAdapter).call(result)
  result = result.transform_keys do |path|
    template_path = path.sub(
      "#{SimpleCov.root}/dummy-app/",
      "#{SimpleCov.root}/lib/generators/solidus_stripe/install/templates/"
    )
    File.exist?(template_path) ? template_path : path
  end
  result.each do |path, coverage|
    next unless path.end_with?('.erb')

    # Remove the extra trailing lines added by ERB
    coverage[:lines] = coverage[:lines][...File.read(path).lines.size]
  end
  result
end

warn "Tracking coverage on process #{$$}..."
SimpleCov.start do
  root __dir__
  enable_coverage_for_eval
  add_filter %r{dummy-app/(db|config|spec|tmp)/}
  track_files "#{SimpleCov.root}/{dummy-app,lib,app}/**/*.{rb,erb}}"
end
