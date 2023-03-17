# frozen_string_literal: true

require 'coverage'
require 'simplecov'

SimpleCov.root File.expand_path(__dir__)

if ENV['CODECOV_TOKEN']
  require 'codecov'

  class FixedCodeCovFormatter
    # The `file_network` method will run a wildcard from inside the current dir
    # instead of inside the SimpleCov root.
    def format(result)
      Dir.chdir(SimpleCov.root) do
        SimpleCov::Formatter::Codecov.new.format(result)
      end
    end
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    FixedCodeCovFormatter,
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

SimpleCov.start do
  root __dir__
  enable_coverage_for_eval
  add_filter %r{dummy-app/(db|config|spec|tmp)/}
  track_files "#{SimpleCov.root}/{dummy-app,lib,app}/**/*.{rb,erb}}"
end
