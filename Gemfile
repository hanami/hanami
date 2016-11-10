source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'
gem 'hanami-utils',       '~> 0.9', require: false, github: 'hanami/utils',       branch: '0.9.x'
gem 'hanami-validations', '~> 0.7', require: false, github: 'hanami/validations', branch: '0.7.x'
gem 'hanami-router',      '~> 0.8', require: false, github: 'hanami/router',      branch: '0.8.x'
gem 'hanami-controller',  '~> 0.7', require: false, github: 'hanami/controller',  branch: '0.8.x'
gem 'hanami-view',        '~> 0.7', require: false, github: 'hanami/view',        branch: '0.8.x'
gem 'hanami-model',       '~> 0.7', require: false, github: 'hanami/model',       branch: '0.7.x'
gem 'hanami-helpers',     '~> 0.5', require: false, github: 'hanami/helpers',     branch: '0.5.x'
gem 'hanami-mailer',      '~> 0.4', require: false, github: 'hanami/mailer',      branch: '0.4.x'
gem 'hanami-assets',      '~> 0.4', require: false, github: 'hanami/assets',      branch: '0.4.x'

platforms :ruby do
  gem 'sqlite3'
end

platforms :jruby do
  gem 'jdbc-sqlite3'
end

# `hanami console` integration tests
gem 'pry',  require: false
gem 'ripl', require: false

# `hanami server` integration tests
gem 'puma',    require: false
gem 'unicorn', require: false, platforms: :ruby

# `hanami server` integration tests (web pages)
gem 'capybara', require: false

if RUBY_DESCRIPTION =~ /linux/
  gem 'therubyracer', require: false, platforms: :ruby
  gem 'therubyrhino', require: false, platforms: :jruby
end

if RUBY_DESCRIPTION =~ /linux|jruby/
  gem 'poltergeist', require: false
else
  gem 'capybara-webkit', require: false
end

# `hanami assets` integration tests
gem 'sass',          require: false
gem 'coffee-script', require: false

# HTTP tests
gem 'excon', require: false

gem 'dotenv',    '~> 2.0',    require: false
gem 'shotgun',   '~> 0.9',    require: false
gem 'rubocop',   '~> 0.43.0', require: false
gem 'coveralls',              require: false
