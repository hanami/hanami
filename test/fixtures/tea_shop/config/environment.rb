require 'rubygems'
require 'hanami/setup'
require_relative '../lib/tea_shop'
require_relative '../apps/web/application'
require_relative '../apps/api/application'

module TeaShop
  class Container < ::Hanami::Container
    configure do
      mount ::Api::Application, at: '/api'
      mount ::Web::Application, at: '/'
    end
  end
end
