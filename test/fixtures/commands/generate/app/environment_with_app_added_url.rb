require 'rubygems'
require 'bundler/setup'
require 'lotus/setup'
require_relative '../lib/container-app'
require_relative '../apps/admin/application'
require_relative '../apps/web/application'

Lotus::Container.configure do
  mount Admin::Application, at: '/backend'
  mount Web::Application, at: '/'
end
