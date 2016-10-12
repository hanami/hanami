require 'hanami/static'
require 'hanami/assets/compiler'
require 'hanami/assets/asset'

# Copyright notice
#
# This file contains a method copied from Rack::Static (rack gem).
#
# Rack - Copyright (C) 2007 Christian Neukirchen
# Released under the MIT License

module Hanami
  module Assets
    # Serve static assets in development environments (development, test).
    #
    # While serving static assets is a role delegated in production to web
    # servers (like Nginx), in development it's rare to use a web server.
    # For this purpose Hanami enables this Rack middleware to serve static
    # assets in development (and test) phase.
    #
    # The other important role of `Hanami::Assets::Static` is to lazily compile
    # (or copy) the assets into the public directory.
    #
    # @since 0.8.0
    # @api private
    #
    # @see Hanami::Static
    class Static < Hanami::Static
      # @since 0.8.0
      # @api private
      PATH_INFO = 'PATH_INFO'.freeze

      # @since 0.8.0
      # @api private
      def initialize(app)
        super(app, header_rules: [])
        @sources = _sources_from_applications
      end

      # @since 0.8.0
      # @api private
      def call(env)
        asset = Assets::Asset.new(@sources, env[PATH_INFO])

        if serve?(asset)
          precompile(asset)
          serve(env, asset)
        else
          @app.call(env)
        end
      end

      private

      # @since 0.8.0
      # @api private
      def serve?(asset)
        can_serve(asset.path) || asset.exist? || asset.precompile?
      end

      # @since 0.8.0
      # @api private
      def precompile(asset)
        Hanami::Assets::Compiler.compile(asset.config, asset.original) if asset.precompile?
      end

      # Copyright notice
      #
      # This method is copied from Rack::Static#call
      #
      # Rack - Copyright (C) 2007 Christian Neukirchen
      # Released under the MIT License
      #
      # @since 0.8.0
      # @api private
      #
      # @see http://www.rubydoc.info/gems/rack/Rack%2FStatic%3Acall
      def serve(env, asset)
        path = asset.path
        env[PATH_INFO] = (path =~ /\/$/ ? path + @index : @urls[path]) if overwrite_file_path(path)
        path = env[PATH_INFO]
        response = @file_server.call(env)

        headers = response[1]
        applicable_rules(path).each do |_, new_headers|
          new_headers.each { |field, content| headers[field] = content }
        end

        response
      end

      # @since 0.8.0
      # @api private
      def _sources_from_applications
        Hanami::Components.resolve('apps.assets.configurations')
        Hanami::Components['apps.assets.configurations'].each_with_object({}) do |config, result|
          result["#{config.prefix}/"] = config
        end
      end
    end
  end
end
