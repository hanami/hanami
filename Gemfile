source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'

gem 'hanami-utils',       '~> 1.2', require: false, git: 'https://github.com/hanami/utils.git',       branch: 'develop'
gem 'hanami-validations', '~> 1.2', require: false, git: 'https://github.com/hanami/validations.git', branch: 'develop'
gem 'hanami-router',      '~> 1.2', require: false, git: 'https://github.com/hanami/router.git',      branch: 'develop'
gem 'hanami-controller',  '~> 1.2', require: false, git: 'https://github.com/hanami/controller.git',  branch: 'develop'
gem 'hanami-view',        '~> 1.2', require: false, git: 'https://github.com/hanami/view.git',        branch: 'develop'
gem 'hanami-model',       '~> 1.2', require: false, git: 'https://github.com/hanami/model.git',       branch: 'develop'
gem 'hanami-helpers',     '~> 1.2', require: false, git: 'https://github.com/hanami/helpers.git',     branch: 'develop'
gem 'hanami-mailer',      '~> 1.2', require: false, git: 'https://github.com/hanami/mailer.git',      branch: 'develop'
gem 'hanami-assets',      '~> 1.2', require: false, git: 'https://github.com/hanami/assets.git',      branch: 'develop'
gem 'hanami-cli',         '~> 0.2', require: false, git: 'https://github.com/hanami/cli.git',         branch: 'develop'

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

if RUBY_DESCRIPTION =~ /linux/
  gem 'therubyracer', require: false, platforms: :ruby
  gem 'therubyrhino', require: false, platforms: :jruby
end

# `hanami assets` integration tests
gem 'sass',          require: false
gem 'coffee-script', require: false

gem 'dotenv',    '~> 2.0', require: false
gem 'shotgun',   '~> 0.9', require: false

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git'
gem 'hanami-webconsole', require: false, git: 'https://github.com/hanami/webconsole.git'

# https://github.com/hanami/hanami/issues/893
gem 'builder'
