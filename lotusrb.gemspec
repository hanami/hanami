# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lotus/version'

Gem::Specification.new do |spec|
  spec.name          = 'lotusrb'
  spec.version       = Lotus::VERSION
  spec.authors       = ['Luca Guidi']
  spec.email         = ['me@lucaguidi.com']
  spec.summary       = %q{A complete web framework for Ruby}
  spec.description   = %q{A complete web framework for Ruby}
  spec.homepage      = 'http://lotusrb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'lotus-utils',      '~> 0.1'
  spec.add_dependency 'lotus-router',     '~> 0.1'
  spec.add_dependency 'lotus-controller', '~> 0.1'
  spec.add_dependency 'lotus-view',       '~> 0.1'

  spec.add_development_dependency 'bundler',   '~> 1.6'
  spec.add_development_dependency 'rake',      '~> 10'
  spec.add_development_dependency 'rack-test', '~> 0.6'
end
