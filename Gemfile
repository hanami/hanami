source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',   require: false
end

gem 'lotus-utils',      '~> 0.3', '>= 0.3.0.dev', require: false, github: 'lotus/utils',      branch: '0.3.x'
gem 'lotus-router',               '>= 0.2.0.dev', require: false, github: 'lotus/router',     branch: '0.2.x'
gem 'lotus-controller',           '>= 0.3.0.dev', require: false, github: 'lotus/controller', branch: '0.3.x'
gem 'lotus-view',                 '>= 0.3.0.dev', require: false, github: 'lotus/view',       branch: '0.3.x'
gem 'lotus-model',                                require: false, github: 'lotus/model'

gem 'simplecov', require: false
gem 'coveralls', require: false
