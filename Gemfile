source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',   require: false
end

gem 'lotus-utils',       '~> 0.5', require: false, github: 'lotus/utils',       branch: '0.5.x'
gem 'lotus-validations', '~> 0.3', require: false, github: 'lotus/validations', branch: '0.3.x'
gem 'lotus-router',      '~> 0.4', require: false, github: 'lotus/router',      branch: '0.4.x'
gem 'lotus-controller',  '~> 0.4', require: false, github: 'lotus/controller',  branch: '0.4.x'
gem 'lotus-view',        '~> 0.4', require: false, github: 'lotus/view',        branch: '0.4.x'
gem 'lotus-model',       '~> 0.4', require: false, github: 'lotus/model',       branch: '0.4.x'
gem 'lotus-helpers',     '~> 0.2', require: false, github: 'lotus/helpers',     branch: '0.2.x'

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

gem 'simplecov', require: false
gem 'coveralls', require: false
