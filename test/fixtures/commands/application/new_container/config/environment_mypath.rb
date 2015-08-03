require 'rubygems'
require 'bundler/setup'
require 'lotus/setup'
require_relative '../lib/new_container'
require_relative '../apps/web/application'

Lotus::Container.configure do
  mount Web::Application, at: '/mypath'
end
