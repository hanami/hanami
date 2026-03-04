# frozen_string_literal: true

RSpec.configure do |config|
  config.before :suite do
    require "hanami/devtools/integration"
    Pathname.new(Dir.pwd).join("tmp").mkpath
  end
end
