source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug',           require: false, platforms: :ruby if RUBY_VERSION >= '2.1.0'
  gem 'yard',             require: false
end

gem 'lotus-utils',      require: false, github: 'lotus/utils'
gem 'lotus-router',     require: false, github: 'lotus/router'
gem 'lotus-controller', require: false, github: 'lotus/controller'
gem 'lotus-view',       require: false, github: 'lotus/view', branch: 'configuration'

gem 'simplecov',   require: false
gem 'coveralls',   require: false
