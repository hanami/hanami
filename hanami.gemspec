# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami"
  spec.version       = Hanami::VERSION
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]
  spec.summary       = "The web, with simplicity"
  spec.description   = "Hanami is a web framework for Ruby"
  spec.homepage      = "http://hanamirb.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files -c -o --exclude-standard -z -- lib/* bin/* LICENSE.md README.md CODE_OF_CONDUCT.md CHANGELOG.md FEATURES.md hanami.gemspec`.split("\x0") # rubocop:disable Layout/LineLength
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.add_dependency "bundler",           ">= 1.16", "< 3"
  spec.add_dependency "dry-configurable",  "~> 0.12", ">= 0.12.1"
  spec.add_dependency "dry-core",          "~> 0.4"
  spec.add_dependency "dry-inflector",     "~> 0.2", ">= 0.2.1"
  spec.add_dependency "dry-monitor"
  spec.add_dependency "dry-system",        "~> 0.23", ">= 0.23.0"
  spec.add_dependency "hanami-cli",        "~> 2.0.alpha"
  spec.add_dependency "hanami-utils",      "~> 2.0.alpha"
  spec.add_dependency "zeitwerk",          "~> 2.4"

  spec.add_development_dependency "rspec",     "~> 3.8"
  spec.add_development_dependency "rack-test", "~> 1.1"
  spec.add_development_dependency "rake",      "~> 13.0"
end
