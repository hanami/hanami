# frozen_string_literal: true

# This file is synced from hanakai-rb/repo-sync

if ENV["COVERAGE"] == "true"
  require "simplecov"
  require "simplecov-cobertura"

  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

  SimpleCov.start do
    add_filter "/spec/"
    enable_coverage :branch
  end
end
