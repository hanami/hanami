# frozen_string_literal: true

require "dry/configurable"
require "dry/core/constants"

module Hanami
  # App settings
  #
  # Users are expected to inherit from this class to define their app settings.
  #
  # @example
  #   # config/settings.rb
  #   # frozen_string_literal: true
  #
  #   require "hanami/settings"
  #   require "my_app/types"
  #
  #   module MyApp
  #     class Settings < Hanami::Settings
  #       setting :database_url
  #       setting :feature_flag, default: false, constructor: Types::Params::Bool
  #     end
  #   end
  #
  # Settings are defined with [dry-configurable](https://dry-rb.org/gems/dry-configurable/), so you
  # can take a look there to see the supported syntax.
  #
  # Users work with an instance of this class made available within the `settings` key in the
  # container. The instance gets its settings populated from a configurable store, which defaults to
  # {Hanami::Settings::EnvStore}.
  #
  # A different store can be set through the `settings_store` Hanami configuration option. All it
  # needs to do is implementing a `#fetch` method with the same signature as `Hash#fetch`.
  #
  # @see Hanami::Settings::DotenvStore
  #
  # @api public
  # @since 2.0.0
  class Settings
    class << self
      def inherited(subclass)
        super

        if Hanami.bundled?("dry-types")
          require "dry/types"
          subclass.const_set(:Types, Dry.Types())
        end
      end

      # Loads the settings for a slice.
      #
      # Returns nil if no settings class is defined.
      #
      # @return [Settings, nil]
      #
      # @api private
      def load_for_slice(slice)
        return unless settings_defined?(slice)

        require_slice_settings(slice) unless slice_settings_class?(slice)

        slice_settings_class(slice).new(slice.config.settings_store)
      end

      private

      # Returns true if settings are defined for the slice.
      #
      # Settings are considered defined if a `Settings` class is already defined in the slice
      # namespace, or a `config/settings.rb` exists under the slice root.
      def settings_defined?(slice)
        slice.namespace.const_defined?(SETTINGS_CLASS_NAME) ||
          slice.root.join("#{SETTINGS_PATH}#{RB_EXT}").file?
      end

      def slice_settings_class?(slice)
        slice.namespace.const_defined?(SETTINGS_CLASS_NAME)
      end

      def slice_settings_class(slice)
        slice.namespace.const_get(SETTINGS_CLASS_NAME)
      end

      def require_slice_settings(slice)
        require "hanami/settings"

        slice_settings_require_path = File.join(slice.root, SETTINGS_PATH)

        begin
          require slice_settings_require_path
        rescue LoadError => e
          raise e unless e.path == slice_settings_require_path
        end
      end
    end

    # Exception for errors in the definition of settings.
    #
    # Its message collects all the individual errors that can be raised for each setting.
    #
    # @api public
    InvalidSettingsError = Class.new(StandardError) do
      def initialize(errors)
        @errors = errors
      end

      def to_s
        <<~STR.strip
          Could not initialize settings. The following settings were invalid:

          #{@errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
        STR
      end
    end

    # @api private
    Undefined = Dry::Core::Constants::Undefined

    # @api private
    EMPTY_STORE = Dry::Core::Constants::EMPTY_HASH

    include Dry::Configurable

    # @api private
    def initialize(store = EMPTY_STORE)
      errors = config._settings.map(&:name).each_with_object({}) do |name, errs|
        value = store.fetch(name, Undefined)

        if value.eql?(Undefined)
          # When a key is missing entirely from the store, _read_ its value from the config instead,
          # which ensures its setting constructor runs (with a `nil` argument given) and raises any
          # necessary errors.
          public_send(name)
        else
          public_send("#{name}=", value)
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        errs[name] = e
      end

      raise InvalidSettingsError, errors if errors.any?

      config.finalize!
    end

    def inspect
      "#<#{self.class.to_s} [#{config._settings.map(&:name).join(", ")}]>"
    end

    def inspect_values
      "#<#{self.class.to_s} #{config._settings.map { |setting| "#{setting.name}=#{config[setting.name].inspect}" }.join(" ")}>"
    end

    private

    def method_missing(name, *args, &block)
      if config.respond_to?(name)
        config.send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, _include_all = false)
      config.respond_to?(name) || super
    end
  end
end
