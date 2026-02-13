# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    class I18n < Hanami::Provider::Source
      SLICE_CONFIGURED_SETTINGS = %i[default_locale available_locales load_path fallbacks].freeze

      DEFAULT_LOCALE = :en
      DEFAULT_AVAILABLE_LOCALES = [].freeze
      DEFAULT_LOAD_PATH = ["config/i18n/**/*.{yml,yaml,json,rb}"].freeze

      setting :default_locale, default: DEFAULT_LOCALE
      setting :available_locales, default: DEFAULT_AVAILABLE_LOCALES
      setting :backend
      setting :load_path, default: DEFAULT_LOAD_PATH
      setting :fallbacks

      def prepare
        require "i18n"

        SLICE_CONFIGURED_SETTINGS.each do |setting|
          next if config.configured?(setting)

          config.public_send(:"#{setting}=", slice.config.i18n.public_send(setting))
        end
      end

      def start
        backend = config.backend || ::I18n::Backend::Simple.new

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

        # Only load translation files if using the default backend. Custom backends are expected to
        # handle their own initialization.
        unless config.backend
          translation_files = resolve_load_paths(Array(config.load_path))
          backend.load_translations(*translation_files) if translation_files.any?
        end

        register "i18n", Backend.new(
          backend,
          locale: config.default_locale,
          default_locale: config.default_locale,
          available_locales: config.available_locales,
          fallbacks: fallbacks_config
        )
      end

      private

      # Resolves load path patterns to actual file paths. Relative patterns are resolved against
      # slice.root. Absolute paths are used as-is.
      def resolve_load_paths(patterns)
        patterns.flat_map do |pattern|
          if absolute_path?(pattern)
            # Absolute path or already-globbed absolute paths
            File.exist?(pattern) ? [pattern] : Dir.glob(pattern)
          else
            # Relative pattern - resolve against slice/app root
            Dir.glob(slice.root.join(pattern))
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
