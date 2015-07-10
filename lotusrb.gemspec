# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lotus/version'

Gem::Specification.new do |spec|
  spec.name          = 'lotusrb'
  spec.version       = Lotus::VERSION
  spec.authors       = ['Luca Guidi', 'Trung Lê', 'Alfonso Uceda Pompa']
  spec.email         = ['me@lucaguidi.com', 'trung.le@ruby-journal.com', 'uceda73@gmail.com']
  spec.summary       = %q{A complete web framework for Ruby}
  spec.description   = %q{A complete web framework for Ruby}
  spec.homepage      = 'http://lotusrb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z -- lib/* bin/* LICENSE.md README.md CHANGELOG.md FEATURES.md lotusrb.gemspec`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'lotus-utils',      '~> 0.5', '>= 0.5.1'
  spec.add_dependency 'lotus-router',     '~> 0.4', '>= 0.4.2'
  spec.add_dependency 'lotus-controller', '~> 0.4', '>= 0.4.4'
  spec.add_dependency 'lotus-view',       '~> 0.4', '>= 0.4.3'
  spec.add_dependency 'lotus-helpers',    '~> 0.2'
  spec.add_dependency 'shotgun',          '~> 0.9'
  spec.add_dependency 'dotenv',           '~> 2.0'
  spec.add_dependency 'thor',             '~> 0.19'

  spec.add_development_dependency 'bundler',   '~> 1.6'
  spec.add_development_dependency 'rake',      '~> 10'
  spec.add_development_dependency 'minitest',  '~> 5'
  spec.add_development_dependency 'rack-test', '~> 0.6'
end
