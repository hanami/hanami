# frozen_string_literal: true

require "dry/configurable"
require "dry/core"
require "uri"
require_relative "../constants"

module Hanami
  module Providers
    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity

    # @api private
    # @since 2.2.0
    class DB < Hanami::Provider::Source
      extend Dry::Core::Cache

      include Dry::Configurable(config_class: Providers::DB::Config)

      setting :adapters, mutable: true, default: Adapters.new
      setting :gateways, default: {}

      def initialize(...)
        super(...)

        @config_finalized = false
      end

      def finalize_config
        return self if @config_finalized

        apply_parent_config if apply_parent_config?

        configure_gateways

        @config_finalized = true

        self
      end

      def prepare
        prepare_and_import_parent_db and return if import_from_parent?

        override_rom_inflector

        finalize_config

        require "hanami-db"

        gateways = prepare_gateways

        if gateways[:default]
          register "gateway", gateways[:default]
        elsif gateways.length == 1
          register "gateway", gateways.values.first
        end
        gateways.each do |key, gateway|
          register "gateways.#{key}", gateway
        end

        @rom_config = ROM::Configuration.new(gateways)

        config.each_plugin do |adapter_name, plugin_spec, config_block|
          if config_block
            @rom_config.plugin(adapter_name, plugin_spec) do |plugin_config|
              instance_exec(plugin_config, &config_block)
            end
          else
            @rom_config.plugin(adapter_name, plugin_spec)
          end
        end

        register "config", @rom_config
      end

      def start
        start_and_import_parent_db and return if import_from_parent?

        # Set up DB logging for the whole app. We share the app's notifications bus across all
        # slices, so we only need to configure the subsciprtion for DB logging just once.
        slice.app.start :db_logging

        # Register ROM components
        register_rom_components :relation, "relations"
        register_rom_components :command, File.join("db", "commands")
        register_rom_components :mapper, File.join("db", "mappers")

        rom = ROM.container(@rom_config)

        register "rom", rom
      end

      def stop
        slice["db.rom"].disconnect
      end

      # @api private
      # @since 2.2.0
      def database_urls
        finalize_config
        config.gateways.transform_values { _1.database_url }
      end

      private

      def parent_db_provider
        return @parent_db_provider if instance_variable_defined?(:@parent_db_provider)

        @parent_db_provider = slice.parent && slice.parent.container.providers[:db]
      end

      def apply_parent_config
        parent_db_provider.source.finalize_config

        self.class.settings.keys.each do |key|
          # Preserve settings already configured locally
          next if config.configured?(key)

          # Skip gateway config, we handle this in #configure_gateways
          next if key == :gateways

          # Skip adapter config, we handle this below
          next if key == :adapters

          config[key] = parent_db_provider.source.config[key]
        end

        parent_db_provider.source.config.adapters.each do |adapter_name, parent_adapter|
          adapter = config.adapter(adapter_name)

          adapter.class.settings.keys.each do |key|
            next if adapter.config.configured?(key)

            adapter.config[key] = parent_adapter.config[key].dup
          end
        end
      end

      def apply_parent_config?
        slice.config.db.configure_from_parent && parent_db_provider
      end

      def import_from_parent?
        slice.config.db.import_from_parent && slice.parent
      end

      def prepare_and_import_parent_db
        return unless parent_db_provider

        slice.parent.prepare :db
        @rom_config = slice.parent["db.config"]

        register "config", (@rom_config = slice.parent["db.config"])
        register "gateway", slice.parent["db.gateway"]
      end

      def start_and_import_parent_db
        return unless parent_db_provider

        slice.parent.start :db

        register "rom", slice.parent["db.rom"]
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

      def configure_gateways
        # Create gateway configs for gateways detected from database_url ENV vars
        database_urls_from_env = detect_database_urls_from_env
        database_urls_from_env.keys.each do |key|
          config.gateways[key] ||= Gateway.new
        end

        # Create a single default gateway if none is configured or detected from database URLs
        config.gateways[:default] = Gateway.new if config.gateways.empty?

        # Leave gateways in a stable order: :default first, followed by others in sort order
        if config.gateways.length > 1
          gateways = config.gateways
          config.gateways = {default: gateways[:default], **gateways.sort.to_h}.compact
        end

        config.gateways.each do |key, gw_config|
          gw_config.database_url ||= database_urls_from_env.fetch(key) {
            raise Hanami::ComponentLoadError, "A database_url for gateway #{key} is required to start :db."
          }

          ensure_database_gem(gw_config.database_url)

          apply_parent_gateway_config(key, gw_config) if apply_parent_config?

          gw_config.configure_adapter(config.adapters)
        end
      end

      def apply_parent_gateway_config(key, gw_config)
        parent_gw_config = parent_db_provider.source.config.gateways[key]

        # Only copy config from a parent gateway with the same name _and_ database URL
        return unless parent_gw_config&.database_url == gw_config.database_url

        # Copy config from matching parent gateway
        (gw_config.class.settings.keys - [:adapter]).each do |key|
          next if gw_config.config.configured?(key)

          gw_config.config[key] = parent_gw_config.config[key].dup
        end

        # If there is an adapter configured within this slice, prefer that, and do not copy the
        # adapter from the parent gateway
        unless config.adapters[gw_config.adapter_name] || gw_config.configured?(:adapter)
          gw_config.adapter = parent_gw_config.adapter.dup
        end
      end

      def prepare_gateways
        config.gateways.transform_values { |gw_config|
          # Avoid spurious connections by reusing identically configured gateways across slices
          fetch_or_store(gw_config.cache_keys) {
            ROM::Gateway.setup(
              gw_config.adapter_name,
              gw_config.database_url,
              **gw_config.options
            )
          }
        }
      end

      def detect_database_urls_from_env
        database_urls = {}

        env_var_prefix = slice.slice_name.name.gsub("/", "__").upcase + "__" unless slice.app?

        # Build gateway URLs from ENV vars with specific gateway named suffixes
        gateway_prefix = "#{env_var_prefix}DATABASE_URL__"
        ENV.select { |(k, _)| k.start_with?(gateway_prefix) }
          .each do |(var, _)|
            gateway_name = var.split(gateway_prefix).last.downcase

            database_urls[gateway_name.to_sym] = ENV[var]
          end

        # Set the default gateway from ENV var without suffix
        unless database_urls.key?(:default)
          fallback_vars = ["#{env_var_prefix}DATABASE_URL", "DATABASE_URL"].uniq

          fallback_vars.each do |var|
            url = ENV[var]
            database_urls[:default] = url and break if url
          end
        end

        # Build URLs from component ENV vars for any gateways without a complete URL
        gateway_names = [:default, *detect_gateway_names_from_env_components(env_var_prefix)]
        (gateway_names - database_urls.keys).each do |gateway_name|
          url = build_database_url_from_env(env_var_prefix, gateway_name)
          database_urls[gateway_name] = url if url
        end

        if Hanami.env?(:test)
          database_urls.transform_values! { Hanami::DB::Testing.database_url(_1) }
        end

        database_urls
      end

      # ENV vars (without any slice prefix or gateway name suffix) from which a database URL can be
      # built when no complete URL is given.
      #
      # @api private
      DATABASE_URL_COMPONENT_VARS = %w[
        DATABASE_ADAPTER
        DATABASE_USER
        DATABASE_PASSWORD
        DATABASE_HOST
        DATABASE_PORT
        DATABASE_NAME
      ].freeze
      private_constant :DATABASE_URL_COMPONENT_VARS

      # Database URL schemes for the adapter names given in DATABASE_ADAPTER. Any other adapter
      # name is used as the scheme as given.
      #
      # @api private
      DATABASE_ADAPTER_SCHEMES = {
        "mysql" => "mysql2",
        "postgresql" => "postgres",
        "sqlite3" => "sqlite"
      }.freeze
      private_constant :DATABASE_ADAPTER_SCHEMES

      # Host to use when no DATABASE_HOST is given.
      #
      # @api private
      DEFAULT_DATABASE_HOST = "localhost"
      private_constant :DEFAULT_DATABASE_HOST

      # Ports to use when no DATABASE_PORT is given, by database URL scheme. Schemes without an
      # entry here get no port at all.
      #
      # @api private
      DEFAULT_DATABASE_PORTS = {
        "mysql2" => "3306",
        "postgres" => "5432"
      }.freeze
      private_constant :DEFAULT_DATABASE_PORTS

      # Returns the names of the gateways with component ENV vars carrying a gateway name suffix,
      # such as DATABASE_HOST__EXTRA.
      def detect_gateway_names_from_env_components(env_var_prefix)
        DATABASE_URL_COMPONENT_VARS.flat_map { |var|
          gateway_prefix = "#{env_var_prefix}#{var}__"

          ENV.keys
            .select { _1.start_with?(gateway_prefix) }
            .map { _1.delete_prefix(gateway_prefix).downcase.to_sym }
        }.uniq
      end

      # Builds the given gateway's database URL from component ENV vars, such as DATABASE_HOST and
      # DATABASE_PORT.
      #
      # The host defaults to localhost, and the port to the adapter's default port, so an adapter
      # alone is enough to connect to a database running locally.
      #
      # Returns nil if no components are given, or if no adapter is given.
      def build_database_url_from_env(env_var_prefix, gateway_name)
        gateway_suffix = "__#{gateway_name.to_s.upcase}" unless gateway_name == :default

        components = DATABASE_URL_COMPONENT_VARS.to_h { |var|
          [var, database_url_component_from_env(var, env_var_prefix, gateway_suffix)]
        }

        return if components.values.all?(&:nil?)

        adapter = components["DATABASE_ADAPTER"]
        return unless adapter

        scheme = DATABASE_ADAPTER_SCHEMES.fetch(adapter, adapter)
        components["DATABASE_HOST"] ||= DEFAULT_DATABASE_HOST
        components["DATABASE_PORT"] ||= DEFAULT_DATABASE_PORTS[scheme]

        name = components["DATABASE_NAME"]

        "#{scheme}://#{database_url_authority(components)}#{"/#{name}" if name}"
      end

      # Returns the value of the first ENV var giving the component, from the most to the least
      # specific:
      #
      #   {SLICE_NAME__}DATABASE_HOST{__GATEWAY_NAME}
      #   {SLICE_NAME__}DATABASE_HOST
      #   DATABASE_HOST__GATEWAY_NAME
      #   DATABASE_HOST
      #
      # This way, gateways and slices can share the components they have in common, and give their
      # own values for the components they do not.
      def database_url_component_from_env(var, env_var_prefix, gateway_suffix)
        vars = [
          "#{env_var_prefix}#{var}#{gateway_suffix}",
          "#{env_var_prefix}#{var}",
          "#{var}#{gateway_suffix}",
          var
        ].uniq

        vars.each do |env_var|
          value = ENV[env_var]
          return value unless value.nil? || value.empty?
        end

        nil
      end

      def database_url_authority(components)
        userinfo = database_url_userinfo(components)
        port = components["DATABASE_PORT"]

        "#{"#{userinfo}@" if userinfo}#{components["DATABASE_HOST"]}#{":#{port}" if port}"
      end

      def database_url_userinfo(components)
        user = components["DATABASE_USER"]
        password = components["DATABASE_PASSWORD"]

        if user && password
          "#{escape_database_url_component(user)}:#{escape_database_url_component(password)}"
        elsif user
          escape_database_url_component(user)
        elsif password
          ":#{escape_database_url_component(password)}"
        end
      end

      def escape_database_url_component(value)
        value.gsub(/[^A-Za-z0-9\-._~]/) { |char| char.bytes.map { format("%%%02X", _1) }.join }
      end

      # @api private
      # @since 2.2.0
      DATABASE_GEMS = {
        "mysql2" => "mysql2",
        "postgres" => "pg",
        "sqlite" => "sqlite3"
      }.freeze
      private_constant :DATABASE_GEMS

      # Raises an error if the relevant database gem for the configured database_url is not
      # installed.
      #
      # Takes a conservative approach to raising errors. It only does so for the database_url
      # schemes generated by the `hanami new` CLI command. Uknown schemes are ignored and no errors
      # are raised.
      def ensure_database_gem(database_url)
        scheme = URI(database_url).scheme
        return unless scheme

        database_gem = DATABASE_GEMS[scheme]
        return unless database_gem

        return if Hanami.bundled?(database_gem)

        raise Hanami::ComponentLoadError, <<~STR
          The "#{database_gem}" gem is required to connect to #{database_url}. Please add it to your Gemfile.
        STR
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
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

    Dry::System.register_provider_source(
      :db,
      source: DB,
      group: :hanami,
      provider_options: {namespace: true}
    )
  end
end
