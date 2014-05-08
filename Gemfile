source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug',           require: false, platforms: :ruby if RUBY_VERSION == '2.1.1'
  gem 'yard',             require: false
  gem 'lotus-utils',      require: false, github: 'lotus/utils'
  gem 'lotus-router',     require: false, github: 'lotus/router'
  gem 'lotus-controller', require: false, github: 'lotus/controller'
  gem 'lotus-view',       require: false, github: 'lotus/view'
else
  gem 'lotus-utils',      '~> 0.1'
  gem 'lotus-router',     '~> 0.1'
  gem 'lotus-controller', '~> 0.1'
  gem 'lotus-view',       '~> 0.1'
end

gem 'simplecov', require: false
gem 'coveralls', require: false
