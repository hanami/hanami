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
        def configure_from_adapter(other_adapter)
          super

          return if skip_defaults?

          # As part of gateway configuration, every gateway will receive the "any adapter" here,
          # which is a plain `Adapter`, not an `SQLAdapter`. Its configuration will have been merged
          # by `super`, so no further work is required.
          return unless other_adapter.is_a?(self.class)

          extensions.concat(other_adapter.extensions).uniq! unless skip_defaults?(:extensions)
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

          # Configure the plugin via a frozen proc, so it can be properly uniq'ed when configured
          # for multiple gateways. See `Hanami::Providers::DB::Config#each_plugin`.
          plugin(relations: :instrumentation, &INSTRUMENTATION_PLUGIN_CONFIG)

          plugin relations: :auto_restrictions
        end

        # @api private
        INSTRUMENTATION_PLUGIN_CONFIG = -> plugin {
          plugin.notifications = target["notifications"]
        }.freeze
        private_constant :INSTRUMENTATION_PLUGIN_CONFIG

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
          if database_url.to_s.start_with?(%r{postgres(ql)*://})
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
          {extensions: extensions}
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
