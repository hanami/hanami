# frozen_string_literal: true

require "bundler/setup"
require "hanami"

begin
  root = Dir.pwd
  require File.join(root, "config/application")
  require File.join(root, "config/routes")
rescue LoadError; end

Hanami.boot
