require 'rack/static'
require 'hanami/assets/compiler'

module Hanami
  class Static < ::Rack::Static
    PATH_INFO = 'PATH_INFO'.freeze

    def initialize(app)
      super(app, root: Hanami.public_directory, header_rules: _header_rules)
      @sources = _sources_from_applications
    end

    class Asset
      PUBLIC_DIRECTORY = Hanami.public_directory.join('**', '*').to_s.freeze

      # @since x.x.x
      # @api private
      URL_SEPARATOR = '/'.freeze

      attr_reader :path, :config, :original

      def initialize(sources, path)
        @path            = path
        @prefix, @config = sources.find { |p, _| path.start_with?(p) }

        if @prefix && @config
          @original = @config.sources.find(@path.sub(@prefix, ''))
        end
      end

      def precompile?
        original && config
      end

      def exist?
        return true unless original.nil?

        file_path = path.gsub(URL_SEPARATOR, ::File::SEPARATOR)
        destination = find_asset do |a|
          a.end_with?(file_path)
        end

        !destination.nil?
      end

      private

      def find_asset
        Dir[PUBLIC_DIRECTORY].find do |asset|
          yield asset unless ::File.directory?(asset)
        end
      end
    end

    def call(env)
      asset = Asset.new(@sources, env[PATH_INFO])

      if serve?(asset)
        precompile(asset)
        serve(env, asset)
      else
        @app.call(env)
      end
    end

    private

    def serve?(asset)
      can_serve(asset.path) || asset.exist? || asset.precompile?
    end

    def precompile(asset)
      Hanami::Assets::Compiler.compile(asset.config, asset.original) if asset.precompile?
    end

    # Code from Rack::Static
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

    def _sources_from_applications
      Hanami::Application.applications.each_with_object({}) do |application, result|
        config = _assets_configuration(application)
        result["#{ config.prefix }/"] = config
      end
    end

    def _assets_configuration(application)
      application.configuration.namespace::Assets.configuration
    end

    def _header_rules
      unless Hanami.env?(:development, :test)
        [[:all, {'Cache-Control' => 'public, max-age=31536000'}]]
      end
    end
  end
end
