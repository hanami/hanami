require 'rack'

module Lotus
  module Commands
    class Server < ::Rack::Server
      def options
        @options ||= parse_options(ARGV.slice(1..-1))
      end
    end
  end
end
