# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "hanami/plugin/version"

Gem::Specification.new do |spec|
  spec.name          = "hanami-plugin"
  spec.version       = Hanami::Plugin::VERSION
  spec.authors       = ["Luca Guidi"]
  spec.email         = ["me@lucaguidi.com"]

  spec.summary       = %q{Hanami Plugin}
  spec.description   = %q{Extend Hanami with super powers}
  spec.homepage      = "http://hanamirb.org"

    spec.metadata["allowed_push_host"] = "http://fakegemserver.hanamirb.org"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
end
