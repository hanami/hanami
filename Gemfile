source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'pry',    require: false, platforms: :jruby
  gem 'yard',   require: false
end

gem 'dry-struct',     require: false, github: 'dry-rb/dry-struct'     # FIXME: this is needed until they will release 0.1
gem 'dry-types',      require: false, github: 'dry-rb/dry-types'      # FIXME: this is needed until they will release 0.9
gem 'dry-validation', require: false, github: 'dry-rb/dry-validation' # FIXME: this is needed until they will release 0.10

gem 'sass'
gem 'i18n'
gem 'hanami-utils',       '~> 0.8', require: false, github: 'hanami/utils',       branch: '0.8.x'
gem 'hanami-validations', '~> 0.6', require: false, github: 'hanami/validations', branch: 'master'
gem 'hanami-router',      '~> 0.7', require: false, github: 'hanami/router',      branch: '0.7.x'
gem 'hanami-controller',  '~> 0.7', require: false, github: 'hanami/controller',  branch: '0.7.x'
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
gem 'rubocop',   require: false

gem 'dotenv', '~> 2.0'
gem 'shotgun', '~> 0.9'
