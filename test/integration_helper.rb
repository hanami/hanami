require_relative './support/helper'
require 'rack/test'

module Minitest
  module IsolationTest
    def self.included(context)
      context.class_eval do
        include Rack::Test::Methods
      end
    end

    private

    def app
      @app
    end

    def response
      last_response
    end

    def request
      last_request
    end

    def ci?
      !!ENV['TRAVIS']
    end
  end
end
