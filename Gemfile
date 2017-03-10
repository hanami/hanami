source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'
gem 'hanami-utils',       '~> 1.0.0.beta1', require: false, github: 'hanami/utils',       branch: '1.0.x'
gem 'hanami-validations', '~> 1.0.0.beta1', require: false, github: 'hanami/validations', branch: '1.0.x'
gem 'hanami-router',      '~> 1.0.0.beta1', require: false, github: 'hanami/router',      branch: '1.0.x'
gem 'hanami-controller',  '~> 1.0.0.beta1', require: false, github: 'hanami/controller',  branch: '1.0.x'
gem 'hanami-view',        '~> 1.0.0.beta1', require: false, github: 'hanami/view',        branch: '1.0.x'
gem 'hanami-model',       '~> 1.0.0.beta1', require: false, github: 'hanami/model',       branch: 'hanami-model-disconnect'
gem 'hanami-helpers',     '~> 1.0.0.beta1', require: false, github: 'hanami/helpers',     branch: '1.0.x'
gem 'hanami-mailer',      '~> 1.0.0.beta1', require: false, github: 'hanami/mailer',      branch: '1.0.x'
gem 'hanami-assets',      '~> 1.0.0.beta1', require: false, github: 'hanami/assets',      branch: '1.0.x'

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

gem 'poltergeist', require: false

# `hanami assets` integration tests
gem 'sass',          require: false
gem 'coffee-script', require: false

# HTTP tests
gem 'excon', require: false

gem 'dotenv',    '~> 2.0',    require: false
gem 'shotgun',   '~> 0.9',    require: false
gem 'rubocop',   '~> 0.43.0', require: false
gem 'coveralls',              require: false
