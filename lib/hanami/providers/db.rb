# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    class DB < Dry::System::Provider::Source
      setting :database_url
      setting :extensions, default: [:error_sql]

      setting :relations_path, default: "relations"

      # @api private
      def prepare
        require "sequel"
        require "rom"
        require "rom/sql"

        # TODO: more database_url logic
        database_url = config.database_url || ENV["DATABASE_URL"]

        # TODO: proper error
        raise "database_url must be configured" unless database_url

        @config = ROM::Configuration.new(:sql, database_url, extensions: config.extensions)

        register "config", @config
        register "connection", @config.gateways[:default]
      end

      # @api private
      def start
        # Loop over relations
        relations_path.glob("*.rb").each do |relation_file|
          relation_name = relation_file
            .relative_path_from(relations_path)
            .basename(relation_file.extname)
            .to_s

          relation_class = target.namespace
            .const_get(:Relations) # TODO don't hardcode
            .const_get(target.inflector.camelize(relation_name))

          # binding.irb

          @config.register_relation(relation_class)
        end

        rom = ROM.container(@config)

        register "rom", rom
      end

      private

      def db_path
        target.app.eql?(target) ? target.root.join("app", "db") : target.root.join("db")
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
