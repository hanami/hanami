source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'

gem 'hanami-utils',       '~> 1.1', require: false, git: 'https://github.com/hanami/utils.git',       branch: '1.1.x'
gem 'hanami-validations', '~> 1.1', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.1.x'
gem 'hanami-router',      '~> 1.1', require: false, git: 'https://github.com/hanami/router.git',      branch: '1.1.x'
gem 'hanami-controller',  '~> 1.1', require: false, git: 'https://github.com/hanami/controller.git',  branch: '1.1.x'
gem 'hanami-view',        '~> 1.1', require: false, git: 'https://github.com/hanami/view.git',        branch: '1.1.x'
gem 'hanami-model',       '~> 1.1', require: false, git: 'https://github.com/hanami/model.git',       branch: '1.1.x'
gem 'hanami-helpers',     '~> 1.1', require: false, git: 'https://github.com/hanami/helpers.git',     branch: '1.1.x'
gem 'hanami-mailer',      '~> 1.1', require: false, git: 'https://github.com/hanami/mailer.git',      branch: '1.1.x'
gem 'hanami-assets',      '~> 1.1', require: false, git: 'https://github.com/hanami/assets.git',      branch: '1.1.x'
gem 'hanami-cli',         '~> 0.1', require: false, git: 'https://github.com/hanami/cli.git',         branch: '0.1.x'

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

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git', branch: 'integration-tools'
