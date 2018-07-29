source 'https://rubygems.org'
gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'

gem 'hanami-utils',       '~> 1.2', require: false, git: 'https://github.com/hanami/utils.git',       branch: 'master'
gem 'hanami-validations', '~> 1.2', require: false, git: 'https://github.com/hanami/validations.git', branch: 'master'
gem 'hanami-router',      '~> 1.2', require: false, git: 'https://github.com/hanami/router.git',      branch: 'master'
gem 'hanami-controller',  '~> 1.2', require: false, git: 'https://github.com/hanami/controller.git',  branch: 'master'
gem 'hanami-view',        '~> 1.2', require: false, git: 'https://github.com/hanami/view.git',        branch: 'master'
gem 'hanami-model',       '~> 1.2', require: false, git: 'https://github.com/hanami/model.git',       branch: 'master'
gem 'hanami-helpers',     '~> 1.2', require: false, git: 'https://github.com/hanami/helpers.git',     branch: 'master'
gem 'hanami-mailer',      '~> 1.2', require: false, git: 'https://github.com/hanami/mailer.git',      branch: 'master'
gem 'hanami-assets',      '~> 1.2', require: false, git: 'https://github.com/hanami/assets.git',      branch: 'master'
gem 'hanami-cli',         '~> 0.2', require: false, git: 'https://github.com/hanami/cli.git',         branch: 'master'

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

gem 'dotenv',    '~> 2.4', require: false
gem 'shotgun',   '~> 0.9', require: false

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git'
gem 'hanami-webconsole', require: false, git: 'https://github.com/hanami/webconsole.git'

# https://github.com/hanami/hanami/issues/893
gem 'builder'
