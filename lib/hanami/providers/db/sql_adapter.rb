# frozen_string_literal: true

module Hanami
  module Providers
    class DB < Hanami::Provider::Source
      # @api public
      # @since 2.2.0
      class SQLAdapter < Adapter
        # @api public
        # @since 2.2.0
        setting :extensions, mutable: true

        # @api public
        # @since 2.2.0
        def extension(*extensions)
          self.extensions.concat(extensions)
        end

        # @api public
        # @since 2.2.0
        def extensions
          config.extensions ||= []
        end

        # @api private
        def configure_for_database(database_url)
          return if skip_defaults?

          configure_plugins
          configure_extensions(database_url)
        end

        # @api private
        private def configure_plugins
          return if skip_defaults?(:plugins)

          plugin relations: :instrumentation do |plugin|
            plugin.notifications = target["notifications"]
          end

          plugin relations: :auto_restrictions
        end

        # @api private
        private def configure_extensions(database_url)
          return if skip_defaults?(:extensions)

          # Extensions for all SQL databases
          extension(
            :caller_logging,
            :error_sql,
            :sql_comments
          )

          # Extensions for specific databases
          if database_url.to_s.start_with?("postgresql://")
            extension(
              :pg_array,
              :pg_enum,
              :pg_json,
              :pg_range
            )
          end
        end

        # @api private
        def gateway_options
          {extensions: config.extensions}
        end

        # @api public
        # @since 2.2.0
        def clear
          config.extensions = nil
          super
        end
      end
    end
  end
end
