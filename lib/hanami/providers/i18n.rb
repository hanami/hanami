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

      # rubocop:disable Metrics/AbcSize
      def start
        backend = config.backend || default_backend

        # Configure fallbacks if enabled (only for default backend, not custom backends)
        fallbacks_config = nil
        if config.fallbacks && !config.backend
          fallbacks_config =
            case config.fallbacks
            when true
              # Use default_locale as the only fallback
              fallbacks = ::I18n::Locale::Fallbacks.new
              fallbacks.defaults = [config.default_locale]
              fallbacks
            when Hash
              # Use explicit per-locale fallback mapping
              ::I18n::Locale::Fallbacks.new(config.fallbacks)
            when Array
              # Use the given fallbacks for all locales
              fallbacks = ::I18n::Locale::Fallbacks.new
              fallbacks.defaults = config.fallbacks
              fallbacks
            else
              ::I18n::Locale::Fallbacks.new(config.fallbacks)
            end
        end

        register "i18n", Backend.new(
          backend,
          locale: config.default_locale,
          default_locale: config.default_locale,
          available_locales: config.available_locales,
          fallbacks: fallbacks_config
        )
      end
      # rubocop:enable Metrics/AbcSize

      private

      # Builds the default backend, used when no custom backend is configured. Custom backends are
      # expected to handle their own initialization.
      #
      # This default backend loads the bundled defaults first, then the shared translation files,
      # then the slice's own translation files, so that later files override earlier ones. It loads
      # everything immediately, so that errors in translation files appear when the slice boots.
      def default_backend
        translation_files = [
          BUNDLED_DEFAULTS_PATH,
          *resolve_load_paths(Array(config.shared_load_path), root: slice.app.root),
          *resolve_load_paths(Array(config.load_path), root: slice.root)
        ].uniq

        SimpleBackend.new(translation_files).tap(&:eager_load!)
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
