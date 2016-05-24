require 'rubygems'
require 'hanami/setup'
require_relative '../lib/coffee_shop'
require_relative '../config/application'

module CoffeeShop
  class Container < ::Hanami::Container
    root "#{ __dir__ }/../"
    configure do
      mount ::CoffeeShop::Application, at: '/'
    end
  end
end
