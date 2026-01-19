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
