# frozen_string_literal: true

require "concurrent/map"
require "i18n"
require "yaml"
require "dry/schema/messages/abstract"

module Hanami
  module Extensions
    module Validation
      # A Dry Schema messages backend that translates validation messages using a Hanami slice's
      # `"i18n"` component, rather than the global `I18n` module used by Dry Schema's own `:i18n`
      # backend.
      #
      # Messages use the same keys as Dry Validation's I18n backend, under a `dry_validation` (for
      # contracts) or `dry_schema` (for plain schemas) top-level key in your translation files:
      #
      #   # config/i18n/fr.yml
      #   fr:
      #     dry_validation:
      #       errors:
      #         filled?: "doit être rempli"
      #
      # When a message is not translated in the current locale, the slice's default locale is tried,
      # followed by Dry Validation's bundled English messages, so that validation never fails for
      # want of a translation.
      #
      # @api private
      # @since 3.1.0
      class Messages < Dry::Schema::Messages::Abstract
        # The locale of Dry Schema's and Dry Validation's bundled messages.
        #
        # @api private
        # @since 3.1.0
        BUNDLED_LOCALE = :en

        # The slice whose `"i18n"` component translates messages. Set via {Builder}, as part of
        # `.build`.
        #
        # @api private
        # @since 3.1.0
        setting :slice

        # Builds a {Messages} backend for a slice. Assigned to a contract's
        # `config.messages.backend`, and called via `Dry::Schema::Messages.setup`.
        #
        # @api private
        # @since 3.1.0
        class Builder
          attr_reader :slice

          def initialize(slice)
            @slice = slice
          end

          def build(options)
            Messages.build({**options, slice:})
          end

          def inspect
            "#<#{self.class.name}[#{slice.name}]>"
          end
        end

        class << self
          # Parsed bundled message files, keyed by path. These files never change at runtime, so
          # are parsed only once.
          #
          # @api private
          def source_cache
            @source_cache ||= Concurrent::Map.new
          end
        end

        # @api private
        attr_reader :t

        # @api private
        def initialize
          super
          @bundled = ::I18n::Backend::Simple.new
          @t = proc { |key, locale: default_locale, **data| lookup(key, locale, **data) }
        end

        # Returns the locale to use when none is given: the slice's current locale (which is
        # thread-local, so follows the locale set for the current request).
        #
        # @api private
        def default_locale
          super || i18n&.locale || BUNDLED_LOCALE
        end

        # Resolves a message template, trying each of {#fallback_locales} in turn.
        #
        # @api private
        def call(predicate, options)
          fallback_locales(options[:locale]).each do |locale|
            result = super(predicate, options.merge(locale:))
            return result if result
          end

          nil
        end
        alias_method :[], :call

        # Resolves a rule (key) name, trying each of {#fallback_locales} in turn.
        #
        # @api private
        def rule(name, options = {})
          fallback_locales(options[:locale]).each do |locale|
            result = super(name, options.merge(locale:))
            return result if result
          end

          nil
        end

        # @api private
        def get(key, options = Dry::Schema::EMPTY_HASH)
          return unless key

          result = lookup(key, options.fetch(:locale, default_locale), **options.except(:locale))

          if result.is_a?(::Hash)
            {text: result[:text], meta: result.except(:text)}
          else
            {text: result, meta: Dry::Schema::EMPTY_HASH}
          end
        end

        # Returns true if the key is translated in the given locale, either by the slice or by the
        # bundled messages. Does not consider fallback locales, so that {#call} can find the most
        # specific message for each locale before falling back.
        #
        # @api private
        def key?(key, options = Dry::Schema::EMPTY_HASH)
          locale = options.fetch(:locale, default_locale)

          i18n_key?(key, locale) || bundled.exists?(locale, key)
        end

        # Loads the bundled message files (Dry Schema's and Dry Validation's defaults, plus any
        # `config.messages.load_paths` added to the contract) into a private store, kept apart from
        # the slice's own translations so they never override them.
        #
        # @api private
        def prepare
          config.load_paths.each do |path|
            data = self.class.source_cache.fetch_or_store(path.to_s) { ::YAML.load_file(path) }

            if custom_top_namespace?(path)
              data = data.transform_values { |messages| {config.top_namespace => messages[Dry::Schema::DEFAULT_MESSAGES_ROOT]} }
            end

            data.each do |locale, translations|
              bundled.store_translations(locale.to_sym, translations)
            end
          end

          slice = config.slice
          @i18n = (slice["i18n"] if slice&.key?("i18n"))

          self
        end

        # @api private
        def interpolatable_data(_key, _options, **data)
          data
        end

        # @api private
        def interpolate(key, options, **data)
          locale = options.fetch(:locale, default_locale)
          text_key = "#{key}.text"
          resolved_key = key?(text_key, locale:) ? text_key : key

          result = lookup(resolved_key, locale, **options.except(:locale), **data)
          result.is_a?(::Hash) ? result[:text] : result
        end

        private

        attr_reader :i18n, :bundled

        def i18n_key?(key, locale)
          i18n&.exists?(key, locale:)
        end

        def fallback_locales(locale)
          [locale || default_locale, i18n&.default_locale, BUNDLED_LOCALE].compact.map(&:to_sym).uniq
        end

        def lookup(key, locale, **data)
          if i18n_key?(key, locale)
            i18n.translate(key, **data, locale:)
          elsif bundled.exists?(locale, key)
            bundled.translate(locale, key, data)
          end
        end
      end
    end
  end
end
