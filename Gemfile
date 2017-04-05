source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'
gem 'hanami-utils',       '~> 1.0', require: false, git: 'https://github.com/hanami/utils.git',       branch: '1.0.x'
gem 'hanami-validations', '~> 1.0', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.0.x'
gem 'hanami-router',      '~> 1.0', require: false, git: 'https://github.com/hanami/router.git',      branch: '1.0.x'
gem 'hanami-controller',  '~> 1.0', require: false, git: 'https://github.com/hanami/controller.git',  branch: '1.0.x'
gem 'hanami-view',        '~> 1.0', require: false, git: 'https://github.com/hanami/view.git',        branch: '1.0.x'
gem 'hanami-model',       '~> 1.0', require: false, git: 'https://github.com/hanami/model.git',       branch: '1.0.x'
gem 'hanami-helpers',     '~> 1.0', require: false, git: 'https://github.com/hanami/helpers.git',     branch: '1.0.x'
gem 'hanami-mailer',      '~> 1.0', require: false, git: 'https://github.com/hanami/mailer.git',      branch: '1.0.x'
gem 'hanami-assets',      '~> 1.0', require: false, git: 'https://github.com/hanami/assets.git',      branch: '1.0.x'

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

gem 'dotenv',    '~> 2.0', require: false
gem 'shotgun',   '~> 0.9', require: false
gem 'rubocop',   '0.48.0', require: false
gem 'coveralls',           require: false
