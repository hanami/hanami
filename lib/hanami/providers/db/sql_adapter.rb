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

        # @api private
        def initialize(...)
          super
          @cleared = false
        end

        # @api private
        def configure_for_database(database_url)
          return if cleared?

          # Extensions for all SQL databases
          extension(
            :caller_logging,
            :error_sql,
            :sql_comments
          )

          # Extensions for specific databases
          if database_url.start_with?("postgresql://")
            extension(
              :pg_array,
              :pg_json,
              :pg_range
            )
          elsif database_url.start_with?("sqlite://")
            extension(:sqlite_json_ops)
          end
        end

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
        def gateway_options
          {extensions: config.extensions}
        end

        # @api public
        # @since 2.2.0
        def clear
          @cleared = true
          config.extensions.clear
          super
        end

        def cleared?
          @cleared
        end
      end
    end
  end
end
