# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/version'
require 'rake/file_list'

Gem::Specification.new do |spec|
  spec.name          = 'hanami'
  spec.version       = Hanami::VERSION
  spec.authors       = ['Luca Guidi']
  spec.email         = ['me@lucaguidi.com']
  spec.summary       = 'The web, with simplicity'
  spec.description   = 'Hanami is a web framework for Ruby'
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = Rake::FileList['{lib,bin}/**/{*,.*}'].exclude(*File.read('.gitignore').split)
                                                            .reject { |f| File.directory?(f) } +
                       %w(LICENSE.md README.md CODE_OF_CONDUCT.md CHANGELOG.md FEATURES.md hanami.gemspec)
  spec.executables   = ['hanami']
  spec.test_files    = Rake::FileList['spec/**/*']
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_dependency 'hanami-utils',       '~> 1.3'
  spec.add_dependency 'hanami-validations', '>= 1.3', '< 3'
  spec.add_dependency 'hanami-router',      '~> 1.3'
  spec.add_dependency 'hanami-controller',  '~> 1.3'
  spec.add_dependency 'hanami-view',        '~> 1.3'
  spec.add_dependency 'hanami-helpers',     '~> 1.3'
  spec.add_dependency 'hanami-mailer',      '~> 1.3'
  spec.add_dependency 'hanami-assets',      '~> 1.3'
  spec.add_dependency 'dry-cli',            '~> 0.5'
  spec.add_dependency 'concurrent-ruby',    '~> 1.0'
  spec.add_dependency 'bundler',            '>= 1.6', '< 3'

  spec.add_development_dependency 'rspec',     '~> 3.7'
  spec.add_development_dependency 'rack-test', '~> 1.1'
  spec.add_development_dependency 'aruba',     '~> 0.14'
  spec.add_development_dependency 'rake',      '~> 13.0'
end
