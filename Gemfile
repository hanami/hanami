source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',   require: false
end

gem 'lotus-utils',      '~> 0.3', '>= 0.3.2', require: false, github: 'lotus/utils',       branch: '0.3.x'
gem 'lotus-router',               '>= 0.2.0', require: false, github: 'lotus/router',      branch: '0.2.x'
gem 'lotus-validations',          '>= 0.2.1', require: false, github: 'lotus/validations', branch: '0.2.x'
gem 'lotus-controller',           '>= 0.3.0', require: false, github: 'lotus/controller',  branch: '0.3.x'
gem 'lotus-view',                 '>= 0.3.0', require: false, github: 'lotus/view',        branch: '0.3.x'
gem 'lotus-model',                '>= 0.2.0', require: false, github: 'lotus/model',       branch: '0.2.x'
gem 'sqlite3'

gem 'simplecov', require: false
gem 'coveralls', require: false
