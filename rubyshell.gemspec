# frozen_string_literal: true

require_relative "lib/rubyshell/version"

Gem::Specification.new do |spec|
  spec.name = "rubyshell"
  spec.version = RubyShell::VERSION
  spec.authors = ["albertalef"]
  spec.email = ["albertalef@protonmail.com"]

  spec.summary = "A rubist way to run shell commands"
  spec.description = "A long description, short for now"
  spec.homepage = "https://github.com/albertalef/rubyshell"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir['CHANGELOG.md', '{lib}/**/*', 'LICENSE.md', 'Rakefile', 'README.md']

  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
