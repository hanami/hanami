# frozen_string_literal: true

require "cgi/escape"

module Hanami
  module Helpers
    # View-layer translation and localization helpers.
    #
    # These helpers are automatically available in your view templates, part classes, and scope
    # classes when the `i18n` gem is bundled. They provide `translate`/`t`, `translate!`/`t!`, and
    # `localize`/`l`, sourcing the i18n backend from the view context and expanding relative
    # (leading-dot) translation keys against the currently-rendering template name.
    #
    # The shared `translate`/`localize` logic lives in {Methods}, which is also included by the
    # action-layer i18n helper ({Hanami::Extensions::Action::I18nHelper}). This module supplies
    # the two view-specific concrete implementations of {Methods}'s abstract hooks: {#_i18n}
    # returns the i18n backend from the view context, and {#_resolve_i18n_key} expands relative
    # keys against the template name.
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
    # @example Relative key lookup
    #   # In app/templates/users/index.html.erb:
    #   <%= translate(".title") %>
    #   # Looks up "users.index.title"
    #
    #   # In app/templates/users/_form.html.erb (a partial):
    #   <%= translate(".label") %>
    #   # Looks up "users._form.label"
    #
    # @api public
    # @since x.x.x
    module I18nHelper
      # Shared `translate` / `localize` (and shorthand) helper methods used by both view-layer
      # consumers and action-layer consumers.
      #
      # **This module is abstract.** Including modules must override two private hooks:
      #
      # - {#_i18n} — returns the i18n backend to delegate to.
      # - {#_resolve_i18n_key} — expands relative (leading-dot) keys against the consumer's
      #   context, and is a no-op for absolute keys.
      #
      # @api public
      # @since x.x.x
      module Methods
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
        # When the key begins with a `.`, it is treated as relative to the consumer's context and
        # expanded by {#_resolve_i18n_key}.
        #
        # @param key [String, Symbol] the translation key to look up
        # @param options [Hash] translation options forwarded to the backend (`:locale`, `:scope`,
        #   `:default`, `:count`, `:raise`, etc.), plus any interpolation values
        #
        # @return [String] the translated string (marked HTML-safe when hanami-view is bundled and
        #   the key ends in `_html` or `html`)
        #
        # @api public
        # @since x.x.x
        def translate(key, **options)
          key = _resolve_i18n_key(key)

          html_safe = _html_safe_translation_key?(key)

          options = _escape_translation_options(options) if html_safe

          result =
            if options.key?(:default) || options[:raise]
              _i18n.translate(key, **options)
            else
              begin
                _i18n.translate(key, **options, raise: true)
              rescue ::I18n::MissingTranslationData => exception
                return _missing_translation_markup(key, exception)
              end
            end

          html_safe ? _i18n_mark_html_safe(result.to_s) : result
        end

        # @api public
        # @since x.x.x
        alias_method :t, :translate

        # Translates the given key, raising an exception if the translation is missing.
        #
        # @param (see #translate)
        #
        # @return [String] the translated string (marked HTML-safe when hanami-view is bundled and
        #   the key ends in `_html` or `html`)
        #
        # @raise [I18n::MissingTranslationData] if the translation is missing
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
        # @api public
        # @since x.x.x
        def localize(object, **options)
          _i18n.localize(object, **options)
        end

        # @api public
        # @since x.x.x
        alias_method :l, :localize

        private

        # Returns the i18n backend the helper methods delegate to.
        #
        # Including modules must override this method to return an I18n backend instance.
        #
        # @return [Hanami::Providers::I18n::Backend]
        def _i18n
          raise NoMethodError, "#{self.class} must implement #_i18n to return an i18n backend"
        end

        # Resolves the given key, returning it unchanged by default.
        #
        # Override this hook to expand relative (leading-dot) keys against a context.
        #
        # @param key [String, Symbol]
        #
        # @return [String, Symbol] the resolved key
        def _resolve_i18n_key(key)
          key
        end

        def _html_safe_translation_key?(key)
          HTML_SAFE_TRANSLATION_KEY.match?(key.to_s)
        end

        def _escape_translation_options(options)
          options.each_with_object({}) do |(key, value), result|
            result[key] =
              if ::I18n::RESERVED_KEYS.include?(key) || !value.is_a?(String) || _i18n_html_safe?(value)
                value
              else
                _i18n_html_escape(value)
              end
          end
        end

        def _missing_translation_markup(key, error)
          title = _i18n_html_escape(error.message)
          body = _i18n_html_escape(key.to_s)
          _i18n_mark_html_safe(%(<span class="translation_missing" title="#{title}">#{body}</span>))
        end

        # Escapes `value` for HTML. Prefers `Hanami::View::Helpers::EscapeHelper#escape_html` when
        # Hanami View's EscapeHelper is included, falling back to stdlib `CGI.escapeHTML` so the
        # helper works in API-only apps that don't bundle hanami-view.
        def _i18n_html_escape(value)
          if respond_to?(:escape_html)
            escape_html(value)
          else
            CGI.escapeHTML(value.to_s)
          end
        end

        # Marks the given string as HTML-safe when Hanami View is loaded, otherwise returns the
        # string unchanged.
        #
        # The HTML-safe marker is only meaningful to Hanami View's template rendering, so there's
        # nothing to do in its absence.
        def _i18n_mark_html_safe(str)
          str.respond_to?(:html_safe) ? str.html_safe : str
        end

        def _i18n_html_safe?(value)
          value.respond_to?(:html_safe?) && value.html_safe?
        end
      end

      include Methods

      private

      def _i18n
        _context.i18n
      end

      def _resolve_i18n_key(key)
        return key unless key.to_s.start_with?(".")

        template_name = _context.current_template_name

        unless template_name
          raise(
            ::I18n::ArgumentError,
            "Cannot use relative translation key #{key.inspect} outside of a template render. " \
            "Use an absolute key (without a leading dot) instead."
          )
        end

        "#{template_name.tr("/", ".")}#{key}"
      end
    end
  end
end
