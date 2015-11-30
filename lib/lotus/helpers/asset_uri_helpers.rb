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

      ASSETS_ROOT_DIRECTORY = (PATH_SEPARATOR + 'assets').freeze

      # Generates the application-specific relative paths for assets
      def asset_path(args = '')

        base_path = ASSETS_ROOT_DIRECTORY + PATH_SEPARATOR + @assets_configuration.prefix.to_s

        base_path + (if args.kind_of? Array
          args.join(PATH_SEPARATOR)
        elsif args.kind_of? String
          args
        else
          raise ArgumentError, "the uri-argument must be kind of an Array- or String-object"
        end)
      end

      # Generates the application-specific absolute URL for assets
      def asset_url(args = '')

      end

      def AssetUriHelpers.included(foreign_module)
        application_name = foreign_module.name.split('::').first
        @application_configuration = Object.const_get("#{application_name}::Application").configuration
        @assets_configuration = @application_configuration.assets

        binding.pry
      end
    end
  end
end
