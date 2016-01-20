source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'pry',    require: false, platforms: :jruby
  gem 'yard',   require: false
end

gem 'sass'
gem 'hanami-utils',       '~> 0.7', require: false, github: 'hanami/utils',       branch: '0.7.x'
gem 'hanami-validations', '~> 0.5', require: false, github: 'hanami/validations', branch: '0.5.x'
gem 'hanami-router',      '~> 0.6', require: false, github: 'hanami/router',      branch: '0.6.x'
gem 'hanami-controller',  '~> 0.6', require: false, github: 'hanami/controller',  branch: '0.6.x'
gem 'hanami-view',        '~> 0.6', require: false, github: 'hanami/view',        branch: '0.6.x'
gem 'hanami-model',       '~> 0.6', require: false, github: 'hanami/model',       branch: '0.6.x'
gem 'hanami-helpers',     '~> 0.3', require: false, github: 'hanami/helpers',     branch: '0.3.x'
gem 'hanami-mailer',      '~> 0.2', require: false, github: 'hanami/mailer',      branch: '0.2.x'
gem 'hanami-assets',      '~> 0.2', require: false, github: 'hanami/assets',      branch: '0.2.x'

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

gem 'simplecov', '~> 0.11', require: false
gem 'coveralls',            require: false
