# frozen_string_literal: true

module Hanami
  module Providers
    class DB < Dry::System::Provider::Source
      # @api public
      # @since 2.2.0
      class SQLAdapter < Adapter
        # @api public
        # @since 2.2.0
        setting :extensions, default: []

        # @api public
        # @since 2.2.0
        def extension(*extensions)
          config.extensions += extensions
        end

        # @api public
        # @since 2.2.0
        def extensions
          config.extensions
        end

        # @api private
        # @since 2.2.0
        def gateway_options
          {extensions: config.extensions}
        end

        # @api private
        # @since 2.2.0
        def clear
          config.extensions.clear
          super
        end
      end
    end
  end
end
