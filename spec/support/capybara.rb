require 'capybara'
require 'capybara/rspec'
require 'capybara/dsl'
require_relative 'platform'

RSpec.configure do |config|
  config.include Capybara::DSL, type: :cli
end

Capybara.configure do |config|
  config.run_server = false

  Platform.match do
    os(:linux) do
      require 'capybara/poltergeist'
      config.default_driver = :poltergeist
    end

    engine(:jruby) do
      require 'capybara/poltergeist'
      config.default_driver = :poltergeist
    end

    os(:macos) do
      require 'capybara/webkit'
      config.default_driver = :webkit
    end
  end
end
