source 'https://rubygems.org'
gemspec

gem 'pry'

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
#  gem 'pry',    require: false, platforms: :jruby # TODO: enable me again
  gem 'yard',   require: false
end

gem 'sass'
gem 'lotus-utils',       '~> 0.6', require: false, github: 'lotus/utils',       branch: '0.6.x'
gem 'lotus-validations', '~> 0.3', require: false, github: 'lotus/validations', branch: '0.3.x'
gem 'lotus-router',      '~> 0.4', require: false, github: 'lotus/router',      branch: '0.5.x'
gem 'lotus-controller',  '~> 0.4', require: false, github: 'lotus/controller',  branch: '0.4.x'
gem 'lotus-view',        '~> 0.4', require: false, github: 'lotus/view',        branch: '0.4.x'
gem 'lotus-model',       '~> 0.5', require: false, github: 'lotus/model',       branch: '0.5.x'
gem 'lotus-helpers',     '~> 0.2', require: false, github: 'lotus/helpers',     branch: '0.2.x'
gem 'lotus-mailer',      '~> 0.1', require: false, github: 'lotus/mailer',      branch: '0.1.x'
gem 'lotus-assets',      '~> 0.1', require: false, github: 'lotus/assets',      branch: 'master'

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

gem 'simplecov', '~> 0.11', require: false
gem 'coveralls',            require: false
