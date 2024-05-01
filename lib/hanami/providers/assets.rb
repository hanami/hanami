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
    class Assets < Dry::System::Provider::Source
      # @api private
      def self.for_slice(slice)
        Class.new(self) do |klass|
          klass.instance_variable_set(:@slice, slice)
        end
      end

      # @api private
      def self.slice
        @slice || Hanami.app
      end

      # @api private
      def prepare
        require "hanami/assets"
      end

      # @api private
      def start
        root = slice.app.root.join("public", "assets", Hanami::Assets.public_assets_dir(slice).to_s)

        assets = Hanami::Assets.new(config: slice.config.assets, root: root)

        register(:assets, assets)
      end

      private

      def slice
        self.class.slice
      end
    end
  end
end
