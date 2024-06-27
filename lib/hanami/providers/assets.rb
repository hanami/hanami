# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Provider source to register routes helper component in Hanami slices.
    #
    # @see Hanami::Slice::RoutesHelper
    #
    # @api private
    # @since 2.0.0
    class Assets < Hanami::Provider::Source
      # @api private
      def prepare
        require "hanami/assets"
      end

      # @api private
      def start
        root = slice.app.root.join("public", "assets", Hanami::Assets.public_assets_dir(target).to_s)

        assets = Hanami::Assets.new(config: slice.config.assets, root: root)

        register(:assets, assets)
      end
    end
  end
end
