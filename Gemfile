source 'https://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug',           require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',             require: false
end

gem 'lotus-utils',       require: false, github: 'rail44/utils', branch: 'add-string-deconstantize'
gem 'lotus-router',      require: false, github: 'lotus/router'
gem 'lotus-validations', require: false, github: 'lotus/validations'
gem 'lotus-controller',  require: false, github: 'lotus/controller'
gem 'lotus-view',        require: false, github: 'lotus/view'

gem 'simplecov',   require: false
gem 'coveralls',   require: false
