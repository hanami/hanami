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
    class DB < Dry::System::Provider::Source
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
        require "sequel"
        require "rom"
        require "rom/sql"

        @config = ROM::Configuration.new(
          :sql,
          ENV["DATABASE_URL"], # TODO: more database_url logic
          extensions: %i[error_sql], # TODO: provider source setting for extensions
        )

        register "config", @config
        register "connection", @config.gateways[:default]
      end

      # @api private
      def start
        # Loop over relations
        db_path.glob("*.rb").each do |relation_file|
          puts relation_file

          relation_name = relation_file.relative_path_from(db_path).basename(relation_file.extname).to_s
          relation_class = slice.namespace.const_get(:DB).const_get(slice.inflector.camelize(relation_name))

          @config.register_relation(relation_class)
        end

        rom = ROM.container(@config)

        register "rom", rom

        rom.relations.each do |name, _|
          register(name) { rom.relations[name] }
        end
      end

      private

      def slice
        self.class.slice
      end

      def db_path
        slice.app.eql?(slice) ? slice.root.join("app", "db") : slice.root.join("db")
      end
    end
  end
end
