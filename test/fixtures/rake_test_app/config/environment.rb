require 'rubygems'
require 'bundler/setup'
require 'lotus/setup'

require_relative '../apps/backend/application'

Lotus::Container.configure do
  mount Backend::Application,   at: '/'
end