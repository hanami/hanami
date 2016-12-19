require 'capybara'
require 'capybara/rspec'
require 'capybara/dsl'
require_relative 'platform'

RSpec.configure do |config|
  config.include Capybara::DSL, type: :cli
end

Capybara.configure do |config|
  config.run_server = false

  require 'capybara/poltergeist'
  config.default_driver = :poltergeist
end
