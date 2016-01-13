require 'rack/static'
require 'lotus/assets/compiler'

module Lotus
  class Static < ::Rack::Static
    PATH_INFO        = 'PATH_INFO'.freeze
    PUBLIC_DIRECTORY = Lotus.public_directory.join('**', '*').to_s.freeze

    def initialize(app)
      super(app, root: Lotus.public_directory, header_rules: _header_rules)
      @sources = _sources_from_applications
    end

    def call(env)
      path           = env[PATH_INFO]

      prefix, config = @sources.find {|p, _| path.start_with?(p) }
      original       = if prefix && config
        config.sources.find(path.sub(prefix, ''))
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
      destination = Dir[PUBLIC_DIRECTORY].find do |file|
        file.index(path).to_i > 0
      end

      (super(path) || !!destination) && _fresh?(original, destination)
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

      Lotus::Assets::Compiler.compile(config, original)
      true
    end

    def _sources_from_applications
      Lotus::Application.applications.each_with_object({}) do |application, result|
        config = _assets_configuration(application)
        result["#{ config.prefix }/"] = config
      end
    end

    def _assets_configuration(application)
      application.configuration.namespace::Assets.configuration
    end

    def _header_rules
      unless Lotus.env?(:development, :test)
        [[:all, {'Cache-Control' => 'public, max-age=31536000'}]]
      end
    end
  end
end
