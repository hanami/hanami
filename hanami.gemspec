# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami'
  spec.version       = Hanami::VERSION
  spec.authors       = ['Luca Guidi', 'Trung Lê', 'Alfonso Uceda Pompa']
  spec.email         = ['me@lucaguidi.com', 'trung.le@ruby-journal.com', 'uceda73@gmail.com']
  spec.summary       = %q{The web, with simplicity.}
  spec.description   = %q{Hanami is a web framework for Ruby}
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z -- lib/* bin/* LICENSE.md README.md CHANGELOG.md FEATURES.md hanami.gemspec`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_dependency 'hanami-utils',      '~> 0.8'
  spec.add_dependency 'hanami-router',     '~> 0.7'
  spec.add_dependency 'hanami-controller', '~> 0.7'
  spec.add_dependency 'hanami-view',       '~> 0.7'
  spec.add_dependency 'hanami-helpers',    '~> 0.4'
  spec.add_dependency 'hanami-mailer',     '~> 0.3'
  spec.add_dependency 'hanami-assets',     '~> 0.3'
  spec.add_dependency 'thor',              '~> 0.19'
  spec.add_dependency 'bundler',           '~> 1.6'

  spec.add_development_dependency 'minispec-metadata', '~> 3.2.1'
  spec.add_development_dependency 'minitest',          '~> 5'
  spec.add_development_dependency 'rack-test',         '~> 0.6'
  spec.add_development_dependency 'rake',              '~> 10'
end
