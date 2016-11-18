# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami'
  spec.version       = Hanami::VERSION
  spec.authors       = ['Luca Guidi', 'Trung Lê', 'Alfonso Uceda Pompa']
  spec.email         = ['me@lucaguidi.com', 'trung.le@ruby-journal.com', 'uceda73@gmail.com']
  spec.summary       = 'The web, with simplicity'
  spec.description   = 'Hanami is a web framework for Ruby'
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -c -o --exclude-standard -z -- lib/* bin/* LICENSE.md README.md CHANGELOG.md FEATURES.md hanami.gemspec`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_dependency 'hanami-utils',       '~> 0.9'
  spec.add_dependency 'hanami-validations', '~> 0.7'
  spec.add_dependency 'hanami-router',      '~> 0.8', '>= 0.8.1'
  spec.add_dependency 'hanami-controller',  '~> 0.8'
  spec.add_dependency 'hanami-view',        '~> 0.8'
  spec.add_dependency 'hanami-helpers',     '~> 0.5'
  spec.add_dependency 'hanami-mailer',      '~> 0.4'
  spec.add_dependency 'hanami-assets',      '~> 0.4'
  spec.add_dependency 'concurrent-ruby',    '~> 1.0'
  spec.add_dependency 'thor',               '~> 0.19'
  spec.add_dependency 'bundler',            '~> 1.13'

  spec.add_development_dependency 'rspec',     '~>  3.5'
  spec.add_development_dependency 'rack-test', '~>  0.6'
  spec.add_development_dependency 'aruba',     '~>  0.14'
  spec.add_development_dependency 'rake',      '~> 11.3'
end
