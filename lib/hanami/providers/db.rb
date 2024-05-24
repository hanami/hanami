# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class DB < Dry::System::Provider::Source
      setting :database_url

      setting :adapter, default: :sql

      # TODO: Determine ideal default extensions
      # TODO: Switch extensions based on configured adapter
      setting :extensions, default: [:error_sql]

      setting :relations_path, default: "relations"

      # @api private
      def prepare
        require "hanami-db"

        # TODO: Add more logic around fetching database URL:
        # - Loading the database URL from settings (if defined)
        # - Check per-slice ENV vars before falling back to DATABASE_URL
        database_url = config.database_url || ENV["DATABASE_URL"]

        unless database_url
          raise Hanami::ComponentLoadError, "A database_url is required to start :db."
        end

        @rom_config = ROM::Configuration.new(config.adapter, database_url, extensions: config.extensions)

        register "config", @rom_config
        register "connection", @rom_config.gateways[:default]
      end

      # @api private
      def start
        # Find and register relations
        relations_path.glob("*.rb").each do |relation_file|
          relation_name = relation_file
            .relative_path_from(relations_path)
            .basename(relation_file.extname)
            .to_s

          relation_class = target.namespace
            .const_get(:Relations) # TODO don't hardcode
            .const_get(target.inflector.camelize(relation_name))

          @rom_config.register_relation(relation_class)
        end

        # TODO: register mappers & commands

        rom = ROM.container(@rom_config)

        register "rom", rom
      end

      private

      def db_path
        if target.app.eql?(target)
          target.root.join("app", "db")
        else
          target.root.join("db")
        end
      end

      def relations_path
        if target.app.eql?(target)
          target.root.join("app", config.relations_path)
        else
          target.root.join(config.relations_path)
        end
      end
    end

    Dry::System.register_provider_source(
      :db,
      source: DB,
      group: :hanami,
      provider_options: {namespace: true}
    )
  end
end
