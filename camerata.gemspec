# frozen_string_literal: true
require_relative 'lib/camerata/version'

Gem::Specification.new do |spec|
  spec.name          = "camerata"
  spec.version       = Camerata::VERSION
  spec.authors       = ["Rob Kaufman"]
  spec.email         = ["rob@notch8.com"]

  spec.summary       = 'Coordinate services for YUL-DC project'
  spec.description   = 'Command line tools and other combined services for the YUL-DC project. Shared Docker and deployment configuration, CI tools, etc live here.'
  spec.homepage      = "https://github.com/yalelibrary/yul-dc-camerata"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yalelibrary/yul-dc-camerata"
  spec.metadata["changelog_uri"] = "https://github.com/yalelibrary/yul-dc-camerata/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) } if File.exist?('.git')
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capybara", "~> 3.33.0"
  spec.add_runtime_dependency "http", "~> 4.4.1"
  spec.add_runtime_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency "selenium-webdriver", "~> 3.142"
  spec.add_runtime_dependency "thor", "~> 1.0.1"
  spec.add_runtime_dependency "activesupport", "~> 6.0.0"
end
