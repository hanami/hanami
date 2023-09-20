# frozen_string_literal: true

require "dry/core/constants"
require "dry/configurable"
require_relative "errors"

module Hanami
  # Provides user-defined settings for an Hanami app or slice.
  #
  # Define your own settings by inheriting from this class in `config/settings.rb` within an app or
  # slice. Your settings will be loaded from matching ENV vars (with upper-cased names) and made
  # registered as a component as part of the Hanami app {Hanami::Slice::ClassMethods#prepare
  # prepare} step.
  #
  # The settings instance is registered in your app and slice containers as a `"settings"`
  # component. You can use the `Deps` mixin to inject this dependency and make settings available to
  # your other components as required.
  #
  # @example
  #   # config/settings.rb
  #   # frozen_string_literal: true
  #
  #   module MyApp
  #     class Settings < Hanami::Settings
  #       Secret = Types::String.constrained(min_size: 20)
  #
  #       setting :database_url, constructor: Types::String
  #       setting :session_secret, constructor: Secret
  #       setting :some_flag, default: false, constructor: Types::Params::Bool
  #     end
  #   end
  #
  # Settings are defined with [dry-configurable][dry-c]'s `setting` method. You may likely want to
  # provide `default:` and `constructor:` options for your settings.
  #
  # If you have [dry-types][dry-t] bundled, then a nested `Types` module will be available for type
  # checking your setting values. Pass type objects to the setting `constructor:` options to ensure
  # their values meet your type expectations. You can use dry-types' default type objects or define
  # your own.
  #
  # When the settings are initialized, all type errors will be collected and presented together for
  # correction. Settings are loaded early, as part of the Hanami app's
  # {Hanami::Slice::ClassMethods#prepare prepare} step, to ensure that the app boots only when valid
  # settings are present.
  #
  # Setting values are loaded from a configurable store, which defaults to
  # {Hanami::Settings::EnvStore}, which fetches the values from equivalent upper-cased keys in
  # `ENV`. You can configure an alternative store via {Hanami::Config#settings_store}. Setting stores
  # must implement a `#fetch` method with the same signature as `Hash#fetch`.
  #
  # [dry-c]: https://dry-rb.org/gems/dry-configurable/
  # [dry-t]: https://dry-rb.org/gems/dry-types/
  #
  # @see Hanami::Settings::DotenvStore
  #
  # @api public
  # @since 2.0.0
  class Settings
    # Error raised when setting values do not meet their type expectations.
    #
    # Its message collects all the individual errors that can be raised for each setting.
    #
    # @api public
    # @since 2.0.0
    class InvalidSettingsError < Hanami::Error
      # @api private
      def initialize(errors)
        super()
        @errors = errors
      end

      # Returns the exception's message.
      #
      # @return [String]
      #
      # @api public
      # @since 2.0.0
      def to_s
        <<~STR.strip
          Could not initialize settings. The following settings were invalid:

          #{@errors.map { |setting, message| "#{setting}: #{message}" }.join("\n")}
        STR
      end
    end

    class << self
      # Defines a nested `Types` constant in `Settings` subclasses if dry-types is bundled.
      #
      # @see https://dry-rb.org/gems/dry-types
      #
      # @api private
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

    # Returns a string containing a human-readable representation of the settings.
    #
    # This includes setting names only, not any values, to ensure that sensitive values do not
    # inadvertently leak.
    #
    # Use {#inspect_values} to inspect settings with their values.
    #
    # @example
    #   settings.inspect
    #   # => #<MyApp::Settings [database_url, session_secret, some_flag]>
    #
    # @return [String]
    #
    # @see #inspect_values
    #
    # @api public
    # @since 2.0.0
    def inspect
      "#<#{self.class} [#{config._settings.map(&:name).join(", ")}]>"
    end

    # rubocop:disable Layout/LineLength

    # Returns a string containing a human-readable representation of the settings and their values.
    #
    # @example
    #   settings.inspect_values
    #   # => #<MyApp::Settings database_url="postgres://localhost/my_db", session_secret="xxx", some_flag=true]>
    #
    # @return [String]
    #
    # @see #inspect
    #
    # @api public
    # @since 2.0.0
    def inspect_values
      "#<#{self.class} #{config._settings.map { |setting| "#{setting.name}=#{config[setting.name].inspect}" }.join(" ")}>"
    end

    # rubocop:enable Layout/LineLength

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
