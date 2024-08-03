# frozen_string_literal: true

require "dry/configurable"
require "dry/core"
require_relative "../constants"

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class DB < Dry::System::Provider::Source
      extend Dry::Core::Cache

      include Dry::Configurable(config_class: Providers::DB::Config)

      setting :database_url
      setting :adapter, default: :sql
      setting :adapters, mutable: true, default: Adapters.new

      def initialize(...)
        super(...)

        @configured_for_database = false
      end

      def finalize_config
        apply_parent_config and return if apply_parent_config?

        configure_for_database
      end

      def prepare
        prepare_and_import_parent_db and return if import_from_parent?

        override_rom_inflector

        finalize_config

        require "hanami-db"

        unless database_url
          raise Hanami::ComponentLoadError, "A database_url is required to start :db."
        end

        # Avoid making spurious connections by reusing identically configured gateways across slices
        gateway = fetch_or_store(database_url, config.gateway_cache_keys) {
          ROM::Gateway.setup(
            config.adapter,
            database_url,
            **config.gateway_options
          )
        }

        @rom_config = ROM::Configuration.new(gateway)

        config.each_plugin do |plugin_spec, config_block|
          if config_block
            @rom_config.plugin(config.adapter, plugin_spec) do |plugin_config|
              instance_exec(plugin_config, &config_block)
            end
          else
            @rom_config.plugin(config.adapter, plugin_spec)
          end
        end

        register "config", @rom_config
        register "gateway", gateway
      end

      # @api private
      def start
        start_and_import_parent_db and return if import_from_parent?

        # Set up DB logging for the whole app. We share the app's notifications bus across all
        # slices, so we only need to configure the subscription for DB logging just once.
        target.app.start :db_logging

        # Register ROM components
        register_rom_components :relation, "relations"
        register_rom_components :command, File.join("db", "commands")
        register_rom_components :mapper, File.join("db", "mappers")

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

      def parent_db_provider
        return @parent_db_provider if instance_variable_defined?(:@parent_db_provider)

        @parent_db_provider = target.parent && target.parent.container.providers[:db]
      end

      def apply_parent_config
        parent_db_provider.source.finalize_config

        self.class.settings.keys.each do |key|
          # Preserve settings already configured locally
          next if config.configured?(key)

          # Skip adapter config, we handle this below
          next if key == :adapters

          config[key] = parent_db_provider.source.config[key]
        end

        parent_db_provider.source.config.adapters.each do |adapter_name, parent_adapter|
          adapter = config.adapters[adapter_name]

          adapter.class.settings.keys.each do |key|
            next if adapter.config.configured?(key)

            adapter.config[key] = parent_adapter.config[key]
          end
        end
      end

      def apply_parent_config?
        target.config.db.configure_from_parent && parent_db_provider
      end

      def configure_for_database
        return if @configured_for_database

        config.adapter(config.adapter_name).configure_for_database(database_url)
        @configured_for_database = true
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

      def register_rom_components(component_type, path)
        components_path = target.source_path.join(path)
        components_path.glob("**/*.rb").each do |component_file|
          component_name = component_file
            .relative_path_from(components_path)
            .sub(RB_EXT_REGEXP, "")
            .to_s

          component_class = target.inflector.camelize(
            "#{target.slice_name.name}/#{path}/#{component_name}"
          ).then { target.inflector.constantize(_1) }

          @rom_config.public_send(:"register_#{component_type}", component_class)
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
