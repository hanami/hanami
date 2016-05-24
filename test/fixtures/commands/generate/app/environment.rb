require 'rubygems'
require 'bundler/setup'
require 'hanami/setup'
require_relative '../lib/container-app'
require_relative '../apps/web/application'

module Haiku
  class Container < Hanami::Container
    configure do
      mount Web::Application, at: '/'
    end
  end
end
