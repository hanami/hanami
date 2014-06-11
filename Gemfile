source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug',           require: false, platforms: :ruby if RUBY_VERSION >= '2.1.0'
  gem 'yard',             require: false
  gem 'lotus-router',     require: false, github: 'lotus/router'
  gem 'lotus-controller', require: false, github: 'lotus/controller'
  gem 'lotus-view',       require: false, github: 'lotus/view', branch: 'configuration'
else
  gem 'lotus-router',     '~> 0.1'
  gem 'lotus-controller', '~> 0.1'
  gem 'lotus-view',       '~> 0.1'
  gem 'lotus-model',      '~> 0.1'
end

gem 'lotus-utils', require: false, github: 'lotus/utils'
gem 'simplecov',   require: false
gem 'coveralls',   require: false
