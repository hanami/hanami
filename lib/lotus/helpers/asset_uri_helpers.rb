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

      # Generates the application-specific relative paths for assets
      def asset_path(*args)
        assets_prefix = _asset_config.prefix
        args.push('') if args.empty?

        path_elements = ['', ASSETS_ROOT_DIRECTORY]
        path_elements.concat(assets_prefix.split(PATH_SEPARATOR).compact) if !assets_prefix.empty?
        path_elements.concat(args)
        path_elements.join(PATH_SEPARATOR)
      end

      # Generates the application-specific absolute URL for assets
      def asset_url(*args)
        path = asset_path(args)

        scheme =  _application_config.scheme
        host =    _application_config.host
        port = if _application_config.port > 0 then
          _application_config.port
        else
          nil # omits the whole port-token when the url will be build
        end

        URI::Generic.build({scheme: scheme, host: host, port: port, path: path}).to_s
      end

      private

      def _assets_class_name
        "#{_application_module_name}::Assets"
      end
      def _application_class_name
        "#{_application_module_name}::Application"
      end
      def _application_module_name
        self.class.name.split('::').first # extract app-name from class-name
      end
      def _asset_config
        @_asset_config ||= Kernel.const_get(_assets_class_name).configuration
      end
      def _application_config
        @_application_config ||= Kernel.const_get(_application_class_name).configuration
      end
    end
  end
end
