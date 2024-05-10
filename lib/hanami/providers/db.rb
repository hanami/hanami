# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    class DB < Dry::System::Provider::Source
      setting :database_url
      setting :extensions, default: [:error_sql]

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
        db_path.glob("*.rb").each do |relation_file|
          puts relation_file

          relation_name = relation_file.relative_path_from(db_path).basename(relation_file.extname).to_s
          relation_class = target.namespace.const_get(:DB).const_get(target.inflector.camelize(relation_name))

          @config.register_relation(relation_class)
        end

        rom = ROM.container(@config)

        register "rom", rom

        rom.relations.each do |name, _|
          register(name) { rom.relations[name] }
        end
      end

      private

      def db_path
        target.app.eql?(target) ? target.root.join("app", "db") : target.root.join("db")
      end
    end

    Dry::System.register_provider_source(:db, source: DB, group: :hanami)
  end
end
