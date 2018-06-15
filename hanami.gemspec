# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami'
  spec.version       = Hanami::VERSION
  spec.authors       = ['Luca Guidi']
  spec.email         = ['me@lucaguidi.com']
  spec.summary       = 'The web, with simplicity'
  spec.description   = 'Hanami is a web framework for Ruby'
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -c -o --exclude-standard -z -- lib/* bin/* LICENSE.md README.md CODE_OF_CONDUCT.md CHANGELOG.md FEATURES.md hanami.gemspec`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_dependency 'hanami-utils',       '~> 2.0.alpha'
  spec.add_dependency 'hanami-validations', '~> 2.0.alpha'
  spec.add_dependency 'hanami-router',      '~> 2.0.alpha'
  spec.add_dependency 'hanami-controller',  '~> 2.0.alpha1'
  spec.add_dependency 'hanami-view',        '~> 2.0.alpha'
  spec.add_dependency 'hanami-helpers',     '~> 2.0.alpha'
  spec.add_dependency 'hanami-mailer',      '~> 2.0.alpha'
  spec.add_dependency 'hanami-assets',      '~> 2.0.alpha'
  spec.add_dependency 'hanami-cli',         '~> 1.0.alpha'
  spec.add_dependency 'concurrent-ruby',    '~> 1.0'
  spec.add_dependency 'dry-inflector',      '~> 0.1'
  spec.add_dependency 'bundler'

  spec.add_development_dependency 'rspec',     '~>  3.7'
  spec.add_development_dependency 'rack-test', '~>  0.6'
  spec.add_development_dependency 'aruba',     '~>  0.14'
  spec.add_development_dependency 'rake',      '~> 12.0'
end
