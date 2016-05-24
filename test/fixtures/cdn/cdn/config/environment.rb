require 'rubygems'
require 'bundler/setup'
require 'hanami/setup'
require_relative '../lib/cdn'
require_relative '../apps/web/application'

module Cdn
  class Container < Hanami::Container
    configure do
      mount Web::Application, at: '/'
    end
  end
end
