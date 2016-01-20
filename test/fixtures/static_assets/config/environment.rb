require 'rubygems'
require 'bundler/setup'
require 'hanami/setup'
require 'tilt/sass'
require_relative '../lib/static_assets'
require_relative '../apps/admin/application'
require_relative '../apps/web/application'

Hanami::Container.configure do
  mount Admin::Application, at: '/admin'
  mount Web::Application, at: '/'
end
