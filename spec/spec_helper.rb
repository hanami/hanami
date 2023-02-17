# frozen_string_literal: true

require "pathname"

SPEC_ROOT = File.expand_path(__dir__).freeze
LOG_DIR = Pathname(SPEC_ROOT).join("..").join("log")

require_relative "support/coverage" if ENV["COVERAGE"].eql?("true")

require "hanami"
begin; require "byebug"; rescue LoadError; end
require "hanami/utils/file_list"
require "hanami/devtools/unit"

Hanami::Utils::FileList["./spec/support/**/*.rb"].each do |file|
  next if file.include?("hanami-plugin")

  require file
end

RSpec.configure do |config|
  config.after(:suite) do
    # TODO: Find out what causes logger to create this dir when running specs.
    #       There's probably a test app class being created somewhere with root
    #       not pointing to a tmp dir.
    FileUtils.rm_rf(LOG_DIR) if LOG_DIR.exist?
  end
end
