# frozen_string_literal: true

require "hanami/view"

module Hanami
  module Helpers
    # Helper methods for translating and localizing content using the slice's i18n backend.
    #
    # These helpers will be automatically available in your view templates, part classes, and scope
    # classes when the `i18n` gem is bundled.
    #
    # @api public
    # @since x.x.x
    module I18nHelper
      # Matches keys whose final segment is `html` or whose final segment ends in `_html`. These
      # translated values are treated as HTML-safe and any string interpolation values are
      # HTML-escaped before substitution.
      #
      # @api private
      HTML_SAFE_TRANSLATION_KEY = /(\b|_)html\z/

      # Translates the given key using the slice's i18n backend.
      #
      # When the key's final segment is `html` or ends in `_html`, the result is marked HTML-safe
      # and any string interpolation values are HTML-escaped first.
      #
      # When a translation is missing and neither `:default` nor `:raise` was supplied, returns a
      # `<span class="translation_missing">` element containing the missing key, useful for
      # spotting missing translations during development.
      #
      # @param key [String, Symbol] the translation key to look up
      # @param options [Hash] translation options forwarded to the backend (`:locale`, `:scope`,
      #   `:default`, `:count`, `:raise`, etc.), plus any interpolation values
      #
      # @return [String, Hanami::View::HTML::SafeString] the translated string
      #
      # @example Basic translation
      #   <%= translate("messages.welcome") %>
      #   # => "Welcome"
      #
      # @example HTML-safe translation
      #   # en.yml
      #   #   greeting_html: "Hello, <strong>%{name}</strong>!"
      #   <%= translate("greeting_html", name: "<script>") %>
      #   # => "Hello, <strong>&lt;script&gt;</strong>!" (marked HTML-safe)
      #
      # @example Missing translation
      #   <%= translate("missing.key") %>
      #   # => '<span class="translation_missing" title="...">missing.key</span>'
      #
      # @api public
      # @since x.x.x
      def translate(key, **options)
        html_safe = _html_safe_translation_key?(key)

        options = _escape_translation_options(options) if html_safe

        result =
          if options.key?(:default) || options[:raise]
            _context.i18n.translate(key, **options)
          else
            begin
              _context.i18n.translate(key, **options, raise: true)
            rescue ::I18n::MissingTranslationData => exception
              return _missing_translation_markup(key, exception)
            end
          end

        html_safe ? result.to_s.html_safe : result
      end

      # @api public
      # @since x.x.x
      alias_method :t, :translate

      # Translates the given key, raising an exception if the translation is missing.
      #
      # @param (see #translate)
      #
      # @return [String, Hanami::View::HTML::SafeString] the translated string
      #
      # @raise [I18n::MissingTranslationData] if the translation is missing
      #
      # @example
      #   <%= translate!("messages.welcome") %>
      #
      # @api public
      # @since x.x.x
      def translate!(key, **options)
        translate(key, **options, raise: true)
      end

      # @api public
      # @since x.x.x
      alias_method :t!, :translate!

      # Localizes the given object (e.g. a date, time, or number) using the slice's i18n backend.
      #
      # @param object [Date, Time, DateTime, Numeric] the object to localize
      # @param options [Hash] localization options forwarded to the backend (`:locale`, `:format`,
      #   etc.)
      #
      # @return [String] the localized string
      #
      # @example
      #   <%= localize(Date.today, format: :long) %>
      #
      # @api public
      # @since x.x.x
      def localize(object, **options)
        _context.i18n.localize(object, **options)
      end

      # @api public
      # @since x.x.x
      alias_method :l, :localize

      private

      def _html_safe_translation_key?(key)
        HTML_SAFE_TRANSLATION_KEY.match?(key.to_s)
      end

      def _escape_translation_options(options)
        options.each_with_object({}) do |(key, value), result|
          result[key] =
            if ::I18n::RESERVED_KEYS.include?(key) || !value.is_a?(String) || value.html_safe?
              value
            else
              escape_html(value)
            end
        end
      end

      def _missing_translation_markup(key, error)
        title = escape_html(error.message)
        body = escape_html(key.to_s)
        %(<span class="translation_missing" title="#{title}">#{body}</span>).html_safe
      end
    end
  end
end
