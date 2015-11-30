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
      def asset_path(args)
      end

      # Generates the application-specific absolute URL for assets
      def asset_url(args)
      end
    end
  end
end
