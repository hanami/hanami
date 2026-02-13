# frozen_string_literal: true

require "dry/configurable"
require_relative "../providers/i18n"

module Hanami
  class Config
    # Hanami I18n config
    #
    # @api public
    # @since x.x.x
    class I18n
      include Dry::Configurable

      # The default locale to use for translations.
      #
      # Default: `:en`
      #
      # @example
      #   config.i18n.default_locale = :fr
      #
      # @api public
      # @since x.x.x
      setting :default_locale, default: Providers::I18n::DEFAULT_LOCALE

      # Array of available locales for the application.
      #
      # When set, only these locales will be considered available, even if translation files exist
      # for other locales. When empty or not set, all locales from loaded translation files are
      # available.
      #
      # Default: `[]` (all loaded locales are available)
      #
      # @example Restrict to specific locales
      #   config.i18n.available_locales = [:en, :fr, :de]
      #
      # @api public
      # @since x.x.x
      setting :available_locales, default: Providers::I18n::DEFAULT_AVAILABLE_LOCALES

      # Array of file path patterns for loading translation files.
      #
      # Patterns can be:
      #
      # - Relative paths/globs (resolved against the app/slice root)
      # - Absolute paths (used as-is)
      #
      # Default: `["config/i18n/**/*.{yml,yaml,json,rb}"]`
      #
      # @example Append custom paths
      #   config.i18n.load_path += ["config/custom_translations/**/*.yml"]
      #
      # @example Replace default paths
      #   config.i18n.load_path = ["translations/**/*.yml"]
      #
      # @api public
      # @since x.x.x
      setting :load_path, default: Providers::I18n::DEFAULT_LOAD_PATH

      # @!attribute [rw] fallbacks
      #   Sets or returns the locale fallbacks configuration for missing translations.
      #
      #   When enabled, the i18n backend will fall back to other locales when a translation is
      #   missing in the requested locale.
      #
      #   This can be set to `true` to enable default fallbacks, a hash to configure explicit
      #   fallback chains per locale, or an array to set a default fallback locale for all locales.
      #
      #   Defaults to `nil` (fallbacks disabled).
      #
      #   @return [Boolean, Hash, Array, nil]
      #
      #   @example Enable default fallbacks
      #     config.i18n.fallbacks = true
      #
      #   @example Configure fallbacks with a hash
      #     config.i18n.fallbacks = {de: [:de, :en], fr: [:fr, :en]}
      #
      #   @example Configure a default fallback locale
      #     config.i18n.fallbacks = [:en]
      #
      #   @api public
      #   @since x.x.x
      setting :fallbacks

      private

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
