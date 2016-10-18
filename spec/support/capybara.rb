require 'capybara'
require 'capybara/rspec'
require 'capybara/dsl'
require 'hanami/utils'

RSpec.configure do |config|
  config.include Capybara::DSL, type: :cli
end

Capybara.configure do |config|
  config.run_server = false

  unless Hanami::Utils.jruby?
    require 'capybara/webkit'
    config.default_driver = :webkit
  end
end
