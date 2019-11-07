# frozen_string_literal: true

require "bundler/setup"
require "hanami"

begin
  require File.join(Dir.pwd, "config/application")
rescue LoadError; end

