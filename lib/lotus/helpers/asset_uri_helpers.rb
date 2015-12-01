require 'uri'

require 'pry'

module Lotus
  module Helpers
    # Helper methods to generate asset-paths
    #
    # @since  0.6.0
    # @api public
    module AssetUriHelpers
      # HTTP-path-separator according to https://tools.ietf.org/html/rfc1738 - 3.3 HTTP
      PATH_SEPARATOR = '/'.freeze

      ASSETS_ROOT_DIRECTORY = 'assets'.freeze

      # Cache-Struct for references to <<app-name>>::Application.configuration and /.assets
      ConfigReferences = Struct.new(:app, :assets)

      # Generates the application-specific relative paths for assets
      def asset_path(*args)
        if @asset_uri_helpers_config.nil? == true then # initialize configuration-cache
          application_name = self.class.name.split('::').first # extract app-name from class-name
          application_configuration = Object.const_get("#{application_name}::Application").configuration
          @asset_uri_helpers_config = Lotus::Helpers::AssetUriHelpers::ConfigReferences.new(
            application_configuration,
            application_configuration.assets
          )
        end

        assets_prefix = @asset_uri_helpers_config[:assets].prefix.to_s
        args.push('') if args.empty?

        path_elements = ['', ASSETS_ROOT_DIRECTORY]
        path_elements.concat(assets_prefix.split(PATH_SEPARATOR).compact) if !assets_prefix.empty?
        path_elements.concat(args)
        path_elements.join(PATH_SEPARATOR)
      end

      # Generates the application-specific absolute URL for assets
      def asset_url(*args)
        url_path = asset_path(args)

        url_scheme = @asset_uri_helpers_config[:app].scheme.to_s
        url_domain = @asset_uri_helpers_config[:app].domain.to_s
        url_port = @asset_uri_helpers_config[:app].port.to_i

        url_port = nil if url_port <= 0

        URI::Generic.build({scheme: url_scheme, host: url_domain, port: url_port, path: url_path}).to_s
      end
    end
  end
end
