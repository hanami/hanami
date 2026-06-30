# frozen_string_literal: true

require "dry/configurable"
require_relative "../providers/i18n"

module Hanami
  class Config
    # Hanami I18n config
    #
    # @api public
    # @since 3.0.0
    class I18n
      include Dry::Configurable

      # @!attribute [rw] default_locale
      #   Sets or returns the default locale to use for translations.
      #
      #   Defaults to `:en`.
      #
      #   @return [Symbol]
      #
      #   @example
      #     config.i18n.default_locale = :fr
      #
      #   @api public
      #   @since 3.0.0
      setting :default_locale, default: Providers::I18n::DEFAULT_LOCALE

      # @!attribute [rw] available_locales
      #   Sets or returns the array of available locales for the application.
      #
      #   When set, only these locales will be considered available, even if translation files exist
      #   for other locales. When empty or not set, all locales from loaded translation files are
      #   available.
      #
      #   Defaults to `[]` (all loaded locales are available).
      #
      #   @return [Array<Symbol>]
      #
      #   @example Restrict to specific locales
      #     config.i18n.available_locales = [:en, :fr, :de]
      #
      #   @api public
      #   @since 3.0.0
      setting :available_locales, default: Providers::I18n::DEFAULT_AVAILABLE_LOCALES

      # @!attribute [rw] load_path
      #   Sets or returns the array of file path patterns for loading per-slice translation files.
      #
      #   Patterns can be:
      #
      #   - Relative paths/globs (resolved against the slice's own root)
      #   - Absolute paths (used as-is)
      #
      #   Defaults to `["config/i18n/**/*.{yml,yaml,json,rb}"]`.
      #
      #   See {#shared_load_path} for common translations that should be loaded into every slice.
      #
      #   @return [Array<String>]
      #
      #   @example Append custom paths
      #     config.i18n.load_path += ["config/custom_translations/**/*.yml"]
      #
      #   @example Replace default paths
      #     config.i18n.load_path = ["translations/**/*.yml"]
      #
      #   @api public
      #   @since 3.0.0
      setting :load_path, default: Providers::I18n::DEFAULT_LOAD_PATH

      # @!attribute [rw] shared_load_path
      #   Sets or returns the array of file path patterns for loading translation files that
      #   should be shared across every slice in the app.
      #
      #   Relative patterns are resolved against the **app root**, regardless of which slice is
      #   being loaded. Absolute paths are used as-is. Files matched by these patterns are loaded
      #   into every slice's i18n backend before that slice's own {#load_path} files, so
      #   slice-specific translations override shared ones on key conflicts.
      #
      #   This is the recommended place for foundational translation data needed by every slice,
      #   such as the `date.*` and `time.*` keys used by `localize`.
      #
      #   Defaults to `["config/i18n/shared/**/*.{yml,yaml,json,rb}"]`.
      #
      #   @return [Array<String>]
      #
      #   @example Disable shared translations
      #     config.i18n.shared_load_path = []
      #
      #   @example Add another shared source
      #     config.i18n.shared_load_path += ["vendor/translations/**/*.yml"]
      #
      #   @api public
      #   @since 3.0.0
      setting :shared_load_path, default: Providers::I18n::DEFAULT_SHARED_LOAD_PATH

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
      #   @since 3.0.0
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
