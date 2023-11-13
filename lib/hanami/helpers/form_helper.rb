# frozen_string_literal: true

require "hanami/view"

module Hanami
  module Helpers
    # Helper methods for generating HTML forms.
    #
    # These helpers will be automatically available in your view templates, part classes and scope
    # classes.
    #
    # This module provides one primary method: {#form_for}, yielding an HTML form builder. This
    # integrates with request params and template locals to populate the form with appropriate
    # values.
    #
    # @api public
    # @since 2.1.0
    module FormHelper
      require_relative "form_helper/form_builder"

      # Default HTTP method for form
      #
      # @since 2.1.0
      # @api private
      DEFAULT_METHOD = "POST"

      # Default charset
      #
      # @since 2.1.0
      # @api private
      DEFAULT_CHARSET = "utf-8"

      # CSRF Token session key
      #
      # This name of this key is shared with the hanami and hanami-controller gems.
      #
      # @since 2.1.0
      # @api private
      CSRF_TOKEN = :_csrf_token

      include Hanami::View::Helpers::TagHelper

      # Yields a form builder for constructing an HTML form and returns the resulting form string.
      #
      # See {FormHelper::FormBuilder} for the methods for building the form's fields.
      #
      # @overload form_for(base_name, url, values: _form_for_values, params: _form_for_params, **attributes)
      #   Builds the form using the given base name for all fields.
      #
      #   @param base_name [String] the base
      #   @param url [String] the URL for submitting the form
      #   @param values [Hash] values to be used for populating form field values; optional,
      #     defaults to the template's locals or to a part's `{name => self}`
      #   @param params [Hash] request param values to be used for populating form field values;
      #     these are used in preference over the `values`; optional, defaults to the current
      #     request's params
      #   @param attributes [Hash] the HTML attributes for the form tag
      #   @yieldparam [FormHelper::FormBuilder] f the form builder
      #
      # @overload form_for(url, values: _form_for_values, params: _form_for_params, **attributes)
      #   @param url [String] the URL for submitting the form
      #   @param values [Hash] values to be used for populating form field values; optional,
      #     defaults to the template's locals or to a part's `{name => self}`
      #   @param params [Hash] request param values to be used for populating form field values;
      #     these are used in preference over the `values`; optional, defaults to the current
      #     request's params
      #   @param attributes [Hash] the HTML attributes for the form tag
      #   @yieldparam [FormHelper::FormBuilder] f the form builder
      #
      # @return [String] the form HTML
      #
      # @see FormHelper
      # @see FormHelper::FormBuilder
      #
      # @example Basic usage
      #   <%= form_for("book", "/books", class: "form-horizontal") do |f| %>
      #     <div>
      #       <%= f.label "title" %>
      #       <%= f.text_field "title", class: "form-control" %>
      #     </div>
      #
      #     <%= f.submit "Create" %>
      #   <% end %>
      #
      #   =>
      #   <form action="/books" method="POST" accept-charset="utf-8" class="form-horizontal">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <div>
      #       <label for="book-title">Title</label>
      #       <input type="text" name="book[title]" id="book-title" value="Test Driven Development">
      #     </div>
      #
      #     <button type="submit">Create</button>
      #   </form>
      #
      # @example Without base name
      #
      #   <%= form_for("/books", class: "form-horizontal") do |f| %>
      #     <div>
      #       <%= f.label "books.title" %>
      #       <%= f.text_field "books.title", class: "form-control" %>
      #     </div>
      #
      #     <%= f.submit "Create" %>
      #   <% end %>
      #
      #   =>
      #   <form action="/books" method="POST" accept-charset="utf-8" class="form-horizontal">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <div>
      #       <label for="book-title">Title</label>
      #       <input type="text" name="book[title]" id="book-title" value="Test Driven Development">
      #     </div>
      #
      #     <button type="submit">Create</button>
      #   </form>
      #
      # @example Method override
      #   <%= form_for("/books/123", method: :put) do |f|
      #     <%= f.text_field "book.title" %>
      #     <%= f.submit "Update" %>
      #   <% end %>
      #
      #   =>
      #   <form action="/books/123" accept-charset="utf-8" method="POST">
      #     <input type="hidden" name="_method" value="PUT">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <input type="text" name="book[title]" id="book-title" value="Test Driven Development">
      #
      #     <button type="submit">Update</button>
      #   </form>
      #
      # @example Overriding values
      #   <%= form_for("/songs", values: {song: {title: "Envision"}}) do |f| %>
      #     <%= f.text_field "song.title" %>
      #     <%= f.submit "Create" %>
      #   <%= end %>
      #
      #   =>
      #   <form action="/songs" accept-charset="utf-8" method="POST">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <input type="text" name="song[title]" id="song-title" value="Envision">
      #
      #     <button type="submit">Create</button>
      #   </form>
      #
      # @api public
      # @since 2.1.0
      def form_for(base_name, url = nil, values: _form_for_values, params: _form_for_params, **attributes)
        url, base_name = base_name, nil if url.nil?

        values = Values.new(values: values, params: params, csrf_token: _form_csrf_token)

        builder = FormBuilder.new(
          base_name: base_name,
          values: values,
          inflector: _context.inflector,
          form_attributes: attributes
        )

        content = (block_given? ? yield(builder) : "").html_safe

        builder.call(content, action: url, **attributes)
      end

      # Returns CSRF meta tags for use via unobtrusive JavaScript (UJS) libraries.
      #
      # @return [String, nil] the tags, if a CSRF token is available, or nil
      #
      # @example
      #   csrf_meta_tags
      #
      #   =>
      #   <meta name="csrf-param" content="_csrf_token">
      #   <meta name="csrf-token" content="4a038be85b7603c406dcbfad4b9cdf91ec6ca138ed6441163a07bb0fdfbe25b5">
      #
      # @api public
      # @since 2.1.0
      def csrf_meta_tags
        return unless (token = _form_csrf_token)

        tag.meta(name: "csrf-param", content: CSRF_TOKEN) +
          tag.meta(name: "csrf-token", content: token)
      end

      # @api private
      # @since 2.1.0
      def _form_for_values
        if respond_to?(:_locals) # Scope
          _locals
        elsif respond_to?(:_name) # Part
          {_name => self}
        else
          {}
        end
      end

      # @api private
      # @since 2.1.0
      def _form_for_params
        _context.request.params
      end

      # @since 2.1.0
      # @api private
      def _form_csrf_token
        return unless _context.request.session_enabled?

        _context.csrf_token
      end
    end
  end
end
