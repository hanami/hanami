# frozen_string_literal: true

SPEC_ROOT = File.expand_path(__dir__).freeze

require_relative "support/coverage" if ENV["COVERAGE"].eql?("true")

require "hanami"
require "hanami/utils/file_list"
require "hanami/devtools/unit"

Hanami::Utils::FileList["./spec/support/**/*.rb"].each do |file|
  next if file.include?("hanami-plugin")

  require file
end
