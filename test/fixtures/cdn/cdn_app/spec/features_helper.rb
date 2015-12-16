# Require this file for feature tests
require_relative './spec_helper'

require 'capybara'
require 'capybara/dsl'

Capybara.app = CdnApp::Application.new

class MiniTest::Spec
  include Capybara::DSL
end
