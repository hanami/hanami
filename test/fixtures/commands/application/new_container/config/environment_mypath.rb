require 'rubygems'
require 'bundler/setup'
require 'hanami/setup'
require_relative '../lib/new_container'
require_relative '../apps/web/application'

module NewContainer
  class Container < Hanami::Container
    configure do
      mount Web::Application, at: '/mypath'
    end
  end
end
