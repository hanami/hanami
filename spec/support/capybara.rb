require 'capybara'
require 'capybara/rspec'
require 'capybara/dsl'
require 'capybara/webkit'

RSpec.configure do |config|
  config.include Capybara::DSL, type: :cli
end

Capybara.configure do |config|
  config.run_server     = false
  config.default_driver = :webkit
end
