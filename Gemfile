source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'pry',    require: false, platforms: :jruby
  gem 'yard',   require: false
end

gem 'dry-logic',      require: false, github: 'dry-rb/dry-logic'
gem 'dry-types',      require: false, github: 'dry-rb/dry-types'
gem 'dry-validation', require: false, github: 'dry-rb/dry-validation'

gem 'sass'
gem 'hanami-utils',       '~> 0.8', require: false, github: 'hanami/utils',       branch: '0.8.x'
gem 'hanami-validations', '~> 0.6', require: false, github: 'hanami/validations', branch: 'master'
gem 'hanami-router',      '~> 0.7', require: false, github: 'hanami/router',      branch: '0.7.x'
gem 'hanami-controller',  '~> 0.7', require: false, github: 'hanami/controller',  branch: 'master'
gem 'hanami-view',        '~> 0.7', require: false, github: 'hanami/view',        branch: '0.7.x'
gem 'hanami-model',       '~> 0.7', require: false, github: 'hanami/model',       branch: '0.7.x'
gem 'hanami-helpers',     '~> 0.4', require: false, github: 'hanami/helpers',     branch: '0.4.x'
gem 'hanami-mailer',      '~> 0.3', require: false, github: 'hanami/mailer',      branch: '0.3.x'
gem 'hanami-assets',      '~> 0.3', require: false, github: 'hanami/assets',      branch: '0.3.x'

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

gem 'coveralls', require: false

gem 'dotenv', '~> 2.0'
gem 'shotgun', '~> 0.9'
