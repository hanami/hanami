# frozen_string_literal: true

require "dry/configurable"
require "dry/core"

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class DB < Dry::System::Provider::Source
      extend Dry::Core::Cache

      include Dry::Configurable(config_class: Providers::DB::Config)

      setting :database_url

      setting :adapter, default: :sql

      # TODO: Determine ideal default extensions
      # TODO: Switch extensions based on configured adapter
      setting :extensions, default: [:error_sql]

      setting :relations_path, default: "relations"

      # @api private
      def prepare
        prepare_and_import_parent_db and return if import_from_parent?

        override_rom_inflector

        apply_parent_config

        require "hanami-db"

        unless database_url
          raise Hanami::ComponentLoadError, "A database_url is required to start :db."
        end

        # Avoid making spurious connections by reusing identically configured gateways across slices
        gateway = fetch_or_store(database_url, config.extensions) {
          ROM::Gateway.setup(
            config.adapter,
            database_url,
            extensions: config.extensions
          )
        }

        @rom_config = ROM::Configuration.new(gateway)

        register "config", @rom_config
        register "gateway", gateway
      end

      # @api private
      def start
        start_and_import_parent_db and return if import_from_parent?

        # Find and register relations
        relations_path = target.source_path.join(config.relations_path)
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

      def stop
        target["db.rom"].disconnect
      end

      # @api private
      def database_url
        return @database_url if instance_variable_defined?(:@database_url)

        # For "main" slice, expect MAIN__DATABASE_URL
        slice_url_var = "#{target.slice_name.name.gsub("/", "__").upcase}__DATABASE_URL"
        chosen_url = config.database_url || ENV[slice_url_var] || ENV["DATABASE_URL"]
        chosen_url &&= Hanami::DB::Testing.database_url(chosen_url) if Hanami.env?(:test)

        @database_url = chosen_url
      end

      private

      def apply_parent_config
        return unless apply_parent_config?

        self.class.settings.keys.each do |key|
          next if config.configured?(key)

          config[key] = parent_db_provider.source.config[key]
        end
      end

      def apply_parent_config?
        target.config.db.configure_from_parent && parent_db_provider
      end

      def parent_db_provider
        return @parent_db_provider if instance_variable_defined?(:@parent_db_provider)

        @parent_db_provider = target.parent &&
          target.parent.container.providers[:db]
      end

      def import_from_parent?
        target.config.db.import_from_parent && target.parent
      end

      def prepare_and_import_parent_db
        return unless parent_db_provider

        target.parent.prepare :db
        @rom_config = target.parent["db.config"]

        register "config", (@rom_config = target.parent["db.config"])
        register "gateway", target.parent["db.gateway"]
      end

      def start_and_import_parent_db
        return unless parent_db_provider

        target.parent.start :db

        register "rom", target.parent["db.rom"]
      end

      # ROM 5.3 doesn't have a configurable inflector.
      #
      # This is a problem in Hanami because using different
      # inflection rules for ROM will lead to constant loading
      # errors.
      def override_rom_inflector
        return if ROM::Inflector == Hanami.app["inflector"]

        ROM.instance_eval {
          remove_const :Inflector
          const_set :Inflector, Hanami.app["inflector"]
        }
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
