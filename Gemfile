source 'https://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'i18n'

gem 'hanami-utils',       '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/utils.git',       branch: 'unstable'
gem 'hanami-validations', '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/validations.git', branch: 'unstable'
gem 'hanami-router',      '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/router.git',      branch: 'unstable'
gem 'hanami-controller',  '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/controller.git',  branch: 'unstable'
gem 'hanami-view',        '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/view.git',        branch: 'unstable'
gem 'hanami-model',       '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/model.git',       branch: 'unstable'
gem 'hanami-helpers',     '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/helpers.git',     branch: 'unstable'
gem 'hanami-mailer',      '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/mailer.git',      branch: 'unstable'
gem 'hanami-assets',      '2.0.0.alpha1', require: false, git: 'https://github.com/hanami/assets.git',      branch: 'unstable'
gem 'hanami-cli',         '1.0.0.alpha1', require: false, git: 'https://github.com/hanami/cli.git',         branch: 'unstable'

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

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git'
gem 'coveralls',       require: false
