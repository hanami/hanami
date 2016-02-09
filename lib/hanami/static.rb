require 'rack/static'
require 'hanami/assets/compiler'

module Hanami
  class Static < ::Rack::Static
    PATH_INFO        = 'PATH_INFO'.freeze
    PUBLIC_DIRECTORY = Hanami.public_directory.join('**', '*').to_s.freeze

    # @since x.x.x
    # @api private
    URL_SEPARATOR       = '/'.freeze

    def initialize(app)
      super(app, root: Hanami.public_directory, header_rules: _header_rules)
      @sources = _sources_from_applications
    end

    def call(env)
      path           = env[PATH_INFO]

      prefix, config = @sources.find { |p, _| path.start_with?(p) }
      if prefix && config
        original = config.sources.find(path.sub(prefix, ''))
      end

      if can_serve(path, original)
        super
      else
        precompile(original, config) ?
          call(env) :
          @app.call(env)
      end
    end

    private

    def can_serve(path, original = nil)
      file_path = path.gsub(URL_SEPARATOR, ::File::SEPARATOR)
      destination = find_asset do |asset|
        asset.end_with?(file_path)
      end

      (super(path) || !!destination) && _fresh?(original, destination)
    end

    def find_asset
      Dir[PUBLIC_DIRECTORY].find do |asset|
        yield asset unless ::File.directory?(asset)
      end
    end

    def _fresh?(original, destination)
      # At this point we're sure that destination exist.
      #
      # If original is missing, it could be a file that a developer manually
      # created into public directory without having the corresponding original.
      # In this case we return true, so the destination file can be served.
      return true if original.nil? || !::File.exist?(original.to_s)

      ::File.mtime(destination) >
        ::File.mtime(original)
    end

    def precompile(original, config)
      return unless original && config

      Hanami::Assets::Compiler.compile(config, original)
      true
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
