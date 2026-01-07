# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync. To update it, edit repo-sync.yml.

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami"
  spec.authors       = ["Hanakai team"]
  spec.email         = ["info@hanakai.org"]
  spec.license       = "MIT"
  spec.version       = Hanami::VERSION.dup

  spec.summary       = "A flexible framework for maintainable Ruby apps"
  spec.description   = spec.summary
  spec.homepage      = "https://hanamirb.org"
  spec.files         = Dir["CHANGELOG.md", "LICENSE", "README.md", "hanami.gemspec", "lib/**/*"]
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.extra_rdoc_files = ["README.md", "CHANGELOG.md", "LICENSE"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["changelog_uri"]     = "https://github.com/hanami/hanami/blob/main/CHANGELOG.md"
  spec.metadata["source_code_uri"]   = "https://github.com/hanami/hanami"
  spec.metadata["bug_tracker_uri"]   = "https://github.com/hanami/hanami/issues"
  spec.metadata["funding_uri"]       = "https://github.com/sponsors/hanami"

  spec.required_ruby_version = ">= 3.2"

  spec.add_runtime_dependency "bundler", ">= 2.0"
  spec.add_runtime_dependency "dry-configurable", "~> 1.0", ">= 1.2.0", "< 2"
  spec.add_runtime_dependency "dry-core", "~> 1.0", "< 2"
  spec.add_runtime_dependency "dry-inflector", "~> 1.0", ">= 1.1.0", "< 2"
  spec.add_runtime_dependency "dry-monitor", "~> 1.0", ">= 1.0.1", "< 2"
  spec.add_runtime_dependency "dry-system", "~> 1.1"
  spec.add_runtime_dependency "dry-logger", "~> 1.2", "< 2"
  spec.add_runtime_dependency "hanami-cli", ">= 2.3.1"
  spec.add_runtime_dependency "hanami-utils", ">= 2.3.0"
  spec.add_runtime_dependency "json", ">= 2.7.2"
  spec.add_runtime_dependency "zeitwerk", "~> 2.6"
  spec.add_runtime_dependency "rack-session"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rack-test", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end

