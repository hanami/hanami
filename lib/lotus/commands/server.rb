require 'rack'

module Lotus
  module Commands
    class Server < ::Rack::Server
      attr_reader :options

      def initialize(options)
        @options = fix_rack_options default_options.merge(options)
      end

      # Primarily this removes the ::Rack::Chunked middleware
      # which is the cause of Safari content-length bugs.
      def middleware
        m = Hash.new { |e, m| e[m] = [] }
        m["deployment"].concat([::Rack::ContentLength, ::Rack::CommonLogger])
        m["development"].concat(m["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
        m
      end

      private

      def default_options
        environment  = ENV['RACK_ENV'] || 'development'
        default_host = environment == 'development' ? 'localhost' : '0.0.0.0'

        {
          environment: environment,
          pid:  nil,
          port: 2300,
          host: default_host,
          accesslog: [],
          config: "config.ru"
        }
      end

      # Frustratingly, some of racks options are capitalized
      # this maps between our command line options and the correct
      # rack options.
      def fix_rack_options(opts)
        opts_map = {
          :port => :Port,
          :host => :Host,
          :accesslog => :AccessLog
        }

        fixed_opts = Hash.new
        opts.each {|k,v| fixed_opts[opts_map.fetch(k, k)] = v }
        fixed_opts
      end
    end
  end
end
