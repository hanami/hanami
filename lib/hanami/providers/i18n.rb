# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    class I18n < Hanami::Provider::Source
      SLICE_CONFIGURED_SETTINGS = %i[
        default_locale available_locales load_path shared_load_path fallbacks
      ].freeze

      DEFAULT_LOCALE = :en
      DEFAULT_AVAILABLE_LOCALES = [].freeze
      DEFAULT_LOAD_PATH = ["config/i18n/**/*.{yml,yaml,json,rb}"].freeze
      DEFAULT_SHARED_LOAD_PATH = ["config/i18n/shared/**/*.{yml,yaml,json,rb}"].freeze

      # Built-in English baseline for date/time localization. Loaded into every slice before any
      # user translation files, so users can supply overrides if desired.
      BUNDLED_DEFAULTS_PATH = File.expand_path("i18n/locale/en.yml", __dir__).freeze

      setting :default_locale, default: DEFAULT_LOCALE
      setting :available_locales, default: DEFAULT_AVAILABLE_LOCALES
      setting :backend
      setting :load_path, default: DEFAULT_LOAD_PATH
      setting :shared_load_path, default: DEFAULT_SHARED_LOAD_PATH
      setting :fallbacks

      def prepare
        require "i18n"

        SLICE_CONFIGURED_SETTINGS.each do |setting|
          next if config.configured?(setting)

          config.public_send(:"#{setting}=", slice.config.i18n.public_send(setting))
        end
      end

      def start
        register "i18n", Backend.new(
          config.backend || default_backend,
          locale: config.default_locale,
          default_locale: config.default_locale,
          available_locales: config.available_locales,
          # Fallbacks apply only to the default backend, not custom backends
          fallbacks: (locale_fallbacks unless config.backend)
        )
      end

      private

      # Returns the default backend, loaded with the translation files. Custom backends are expected
      # to handle their own initialization.
      def default_backend
        ::I18n::Backend::Simple.new.tap do |backend|
          backend.load_translations(*translation_files)
        end
      end

      def translation_files
        [
          BUNDLED_DEFAULTS_PATH,
          *resolve_load_paths(Array(config.shared_load_path), root: slice.app.root),
          *resolve_load_paths(Array(config.load_path), root: slice.root)
        ].uniq
      end

      def locale_fallbacks
        case config.fallbacks
        when nil, false
          nil
        when true
          # Use default_locale as the only fallback
          fallbacks_with_defaults([config.default_locale])
        when Array
          # Use the given fallbacks for all locales
          fallbacks_with_defaults(config.fallbacks)
        else
          # Use explicit per-locale fallback mapping
          ::I18n::Locale::Fallbacks.new(config.fallbacks)
        end
      end

      def fallbacks_with_defaults(defaults)
        ::I18n::Locale::Fallbacks.new.tap do |fallbacks|
          fallbacks.defaults = defaults
        end
      end

      # Resolves load path patterns to actual file paths. Relative patterns are resolved against
      # the given `root`. Absolute paths are used as-is.
      def resolve_load_paths(patterns, root:)
        patterns.flat_map do |pattern|
          if absolute_path?(pattern)
            # Absolute path or already-globbed absolute paths
            File.exist?(pattern) ? [pattern] : Dir.glob(pattern)
          else
            Dir.glob(root.join(pattern))
          end
        end
      end

      def absolute_path?(path)
        Pathname.new(path).absolute?
      end
    end

    Dry::System.register_provider_source(
      :i18n,
      source: I18n,
      group: :hanami
    )
  end
end

require_relative "i18n/backend"
