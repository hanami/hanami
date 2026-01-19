# frozen_string_literal: true

module Hanami
  module Providers
    class I18n < Hanami::Provider::Source
      # A wrapper that provides a full `I18n`-like interface for an individual I18n backend. This
      # allows each Hanami slice to have its own isolated I18n instance.
      #
      # Unlike the global I18n module which uses class variables for configuration,
      # this wrapper maintains per-instance state for true isolation between slices.
      #
      # @api public
      # @since x.x.x
      class Backend
        attr_reader :backend

        # Returns the default locale.
        #
        # @return [Symbol] the default locale
        #
        # @api public
        # @since x.x.x
        attr_reader :default_locale

        # Creates a new Backend instance.
        #
        # @param backend [I18n::Backend::Base] the underlying I18n backend
        # @param locale [Symbol, String, nil] initial locale to set in thread-local storage
        # @param default_locale [Symbol, String] the default locale to use when no locale is set
        # @param available_locales [Array<Symbol, String>] list of available locales
        #
        # @api private
        # @since x.x.x
        def initialize(backend, locale: nil, default_locale: :en, available_locales: [])
          @backend = backend
          @default_locale = default_locale.to_sym
          @available_locales = Array(available_locales).map(&:to_sym)

          # Set initial locale (if provided) in thread-local storage.
          @storage_key = :"hanami_i18n_#{object_id}"
          self.locale = locale if locale
        end

        # Translates the given key.
        #
        # @param key [String, Symbol] the translation key to look up
        # @param options [Hash] translation options
        # @option options [Symbol, String] :locale the locale to use (defaults to current locale)
        # @option options [String, Proc, Array] :default default value if translation is missing
        # @option options [Hash] :scope additional scope for the key
        # @option options [Integer] :count for pluralization
        # @option options [Boolean] :raise whether to raise an exception for missing translations
        #
        # @return [String, Object] the translated string or default value
        #
        # @raise [I18n::MissingTranslationData] if translation is missing and :raise option is true
        #
        # @example Basic translation
        #   translate("hello") # => "Hello"
        #
        # @example Translation with interpolation
        #   translate("greeting", name: "Alice") # => "Hello, Alice"
        #
        # @example With explicit locale
        #   translate("hello", locale: :fr) # => "Bonjour"
        #
        # @api public
        # @since x.x.x
        def translate(key, **options)
          locale = options[:locale] || self.locale

          result = catch(:exception) do
            @backend.translate(locale, key, options)
          end

          if result.is_a?(::I18n::MissingTranslation)
            if options[:raise]
              raise ::I18n::MissingTranslationData.new(locale, key, options)
            else
              handle_missing_translation(result, options)
            end
          else
            result
          end
        end

        # @api public
        # @since x.x.x
        alias_method :t, :translate

        # Translates the given key, raising an exception if translation is missing.
        #
        # @param key [String, Symbol] the translation key to look up
        # @param options [Hash] translation options (see {#translate})
        #
        # @return [String, Object] the translated string
        #
        # @raise [I18n::MissingTranslationData] if translation is missing
        #
        # @example
        #   t!("hello") # => "Hello"
        #   t!("missing.key") # raises I18n::MissingTranslationData
        #
        # @api public
        # @since x.x.x
        def t!(key, **options)
          translate(key, **options.merge(raise: true))
        end

        # Localizes the given object (e.g., date, time, number).
        #
        # @param object [Date, Time, DateTime, Numeric] the object to localize
        # @param locale [Symbol, String, nil] the locale to use (defaults to current locale)
        # @param format [Symbol, String, nil] the format to use for localization
        # @param options [Hash] additional localization options
        #
        # @return [String] the localized string representation
        #
        # @example Localize a date
        #   localize(Date.today, format: :long) # => "January 19, 2026"
        #
        # @example Localize with specific locale
        #   localize(Date.today, locale: :fr, format: :long) # => "19 janvier 2026"
        #
        # @api public
        # @since x.x.x
        def localize(object, locale: nil, format: nil, **options)
          locale ||= self.locale
          @backend.localize(locale, object, format, options)
        end

        # @api public
        # @since x.x.x
        alias_method :l, :localize

        # Returns true if a translation exists for the given key.
        #
        # @param key [String, Symbol] the translation key to check
        # @param locale [Symbol, String, nil] the locale to check (defaults to current locale)
        # @param options [Hash] additional options
        #
        # @return [Boolean] true if the translation exists, false otherwise
        #
        # @example
        #   exists?("hello") # => true
        #   exists?("missing.key") # => false
        #
        # @api public
        # @since x.x.x
        def exists?(key, locale: nil, **options)
          locale ||= self.locale
          @backend.exists?(locale, key, options)
        end

        # Transliterates the given string.
        #
        # @param key [String] the string to transliterate
        # @param locale [Symbol, String, nil] the locale to use (defaults to current locale)
        # @param replacement [String, nil] replacement string for non-transliteratable characters
        # @param options [Hash] additional transliteration options
        #
        # @return [String] the transliterated string
        #
        # @example
        #   transliterate("Ærøskøbing") # => "AEroskobing"
        #
        # @api public
        # @since x.x.x
        def transliterate(key, locale: nil, replacement: nil, **options)
          locale ||= self.locale
          @backend.transliterate(locale, key, replacement)
        end

        # Returns available locales.
        #
        # If configured via `config.i18n.available_locales`, returns the configured locales.
        # Otherwise, returns all locales detected from loaded translation files.
        #
        # @api public
        # @since x.x.x
        def available_locales
          if @available_locales.any?
            @available_locales
          else
            @backend.available_locales
          end
        end

        # Reloads translations from translation files.
        #
        # @return [void]
        #
        # @api public
        # @since x.x.x
        def reload!
          @backend.reload!
        end

        # Eager loads translations if the backend supports it.
        #
        # @return [void]
        #
        # @api public
        # @since x.x.x
        def eager_load!
          @backend.eager_load! if @backend.respond_to?(:eager_load!)
        end

        # Returns the current locale from fiber/thread-local storage, or default_locale.
        #
        # This is thread-safe and works correctly with concurrent requests.
        # Each backend instance maintains its own locale in thread storage.
        #
        # @return [Symbol] the current locale or default locale if none is set
        #
        # @example
        #   locale # => :en
        #   self.locale = :fr
        #   locale # => :fr
        #
        # @api public
        # @since x.x.x
        def locale
          Thread.current[@storage_key] || default_locale
        end

        # Sets the current locale in fiber/thread-local storage.
        #
        # This is thread-safe and works correctly with concurrent requests.
        # Each backend instance maintains its own locale in thread storage.
        #
        # @param value [Symbol, String, nil] the locale to set (converted to symbol)
        #
        # @return [Symbol, nil] the locale value that was set
        #
        # @example
        #   self.locale = :fr
        #   self.locale = "de"
        #   self.locale = nil # resets to default_locale
        #
        # @api public
        # @since x.x.x
        def locale=(value)
          Thread.current[@storage_key] = value&.to_sym
        end

        # Executes a block with a temporary locale.
        #
        # This is useful for executing code with a specific locale without affecting
        # other concurrent requests. The previous locale is restored even if the block raises.
        #
        # @param tmp_locale [Symbol, String, nil] the temporary locale to use
        #
        # @yieldreturn [Object] the return value of the block
        #
        # @return [Object] the return value of the block
        #
        # @example
        #   with_locale(:fr) do
        #     t("greeting") # Uses French locale
        #   end
        #   # locale is restored to previous value
        #
        # @example Nested usage
        #   with_locale(:fr) do
        #     with_locale(:de) do
        #       t("hello") # Uses German
        #     end
        #     t("hello") # Uses French
        #   end
        #
        # @api public
        # @since x.x.x
        def with_locale(tmp_locale)
          previous_locale = Thread.current[@storage_key]
          Thread.current[@storage_key] = tmp_locale&.to_sym
          yield
        ensure
          Thread.current[@storage_key] = previous_locale
        end

        private

        def handle_missing_translation(missing_translation, options)
          default = options[:default]
          return default if default.is_a?(String)

          key = missing_translation.key
          key.to_s
        end
      end
    end
  end
end
