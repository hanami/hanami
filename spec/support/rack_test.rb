require 'rack/test'
require 'excon'
require_relative 'retry'

module RSpec
  module Support
    module RackTest
      private

      def app
        RSpec::Support::RackApp.new
      end
    end

    class RackApp
      include RSpec::Support::Retry

      def initialize
        @connection = Excon.new('http://localhost:2300', persistent: true)
      end

      def call(env)
        retry_exec(Excon::Errors::SocketError) do
          response(
            request(env)
          )
        end
      end

      private

      attr_reader :connection

      def request(env)
        connection.request(options(env))
      end

      def response(r)
        [r.status, r.headers, [r.body]]
      end

      def options(env) # rubocop:disable Metrics/MethodLength
        result = Hash[
          method:  env['REQUEST_METHOD'],
          path:    env['PATH_INFO'],
          headers: {
            'Content-Type' => env['CONTENT_TYPE'],
            'Accept'       => env['HTTP_ACCEPT']
          }
        ]

        unless get?(env)
          env['rack.input'].rewind
          result[:body] = env['rack.input'].read
        end

        result
      end

      def get?(env)
        %w(GET HEAD).include?(env['REQUEST_METHOD'])
      end
    end
  end
end

RSpec.configure do |config|
  config.include Rack::Test::Methods,      type: :cli
  config.include RSpec::Support::RackTest, type: :cli
end
