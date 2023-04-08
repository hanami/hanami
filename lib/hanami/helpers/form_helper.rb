# frozen_string_literal: true

require "hanami/view/helpers/html_helper"

module Hanami
  module Helpers
    # Form builder
    #
    # By including <tt>Hanami::Helpers::FormHelper</tt> it will inject one public method: <tt>form_for</tt>.
    # This is a HTML5 form builder.
    #
    # To understand the general HTML5 builder syntax of this framework, please
    # consider to have a look at <tt>Hanami::Helpers::HtmlHelper</tt> documentation.
    #
    # This builder is independent from any template engine.
    # This was hard to achieve without a compromise: the form helper should be
    # used in one output block in a template or as a method in a view (see the examples below).
    #
    # Features:
    #
    #   * Support for complex markup without the need of concatenation
    #   * Auto closing HTML5 tags
    #   * Support for view local variables
    #   * Method override support (PUT/PATCH/DELETE HTTP verbs aren't understood by browsers)
    #   * Automatic generation of HTML attributes for inputs: <tt>id</tt>, <tt>name</tt>, <tt>value</tt>
    #   * Allow to override HTML attributes
    #   * Extract values from request params and fill <tt>value</tt> attributes
    #   * Automatic selection of current value for radio button and select inputs
    #   * Infinite nested fields
    #
    # Supported tags and inputs:
    #
    #   * <tt>check_box</tt>
    #   * <tt>color_field</tt>
    #   * <tt>date_field</tt>
    #   * <tt>datetime_field</tt>
    #   * <tt>datetime_local_field</tt>
    #   * <tt>email_field</tt>
    #   * <tt>fields_for</tt>
    #   * <tt>file_field</tt>
    #   * <tt>form_for</tt>
    #   * <tt>hidden_field</tt>
    #   * <tt>label</tt>
    #   * <tt>number_field</tt>
    #   * <tt>password_field</tt>
    #   * <tt>radio_button</tt>
    #   * <tt>select</tt>
    #   * <tt>submit</tt>
    #   * <tt>text_area</tt>
    #   * <tt>text_field</tt>
    #
    # @since 2.0.0
    #
    # @see Hanami::Helpers::FormHelper#form_for
    # @see Hanami::Helpers::HtmlHelper
    #
    # @example One output block (template)
    #   <%=
    #     form_for :book, routes.books_path do
    #       text_field :title
    #
    #       submit 'Create'
    #     end
    #   %>
    #
    # @example Method (view)
    #   require 'hanami/helpers'
    #
    #   class MyView
    #     include Hanami::Helpers::FormHelper
    #
    #     def my_form
    #       form_for :book, routes.books_path do
    #         text_field :title
    #       end
    #     end
    #   end
    #
    #   <!-- use this in the template -->
    #   <%= my_form %>
    module FormHelper
      require_relative "form_helper/form_builder"

      # Default HTTP method for form
      #
      # @since 2.0.0
      # @api private
      DEFAULT_METHOD = "POST"

      # Default charset
      #
      # @since 2.0.0
      # @api private
      DEFAULT_CHARSET = "utf-8"

      # CSRF Token session key
      #
      # This key is shared with <tt>hanamirb</tt>, <tt>hanami-controller</tt>.
      #
      # @since 2.0.0
      # @api private
      CSRF_TOKEN = :_csrf_token

      include Hanami::View::Helpers::HTMLHelper

      # Form object
      #
      # @since 2.0.0
      class Form
        # @return [Symbol] the form name
        #
        # @since 2.0.0
        # @api private
        attr_reader :name

        # @return [String] the form action
        #
        # @since 2.0.0
        # @api private
        attr_reader :url

        # @return [::Hash] the form values
        #
        # @since 2.0.0
        # @api private
        attr_reader :values

        # Initialize a form
        #
        # It accepts a set of values that are used in combination with request
        # params to autofill <tt>value</tt> attributes for fields.
        #
        # The keys of this Hash, MUST correspond to the structure of the (nested)
        # fields of the form.
        #
        # For a given input where the <tt>name</tt> is `book[title]`, Hanami will
        # look for `:book` key in values.
        #
        # If the current params have the same key, it will be PREFERRED over the
        # given values.
        #
        # For instance, if <tt>params.get('book.title')</tt> equals to
        # <tt>"TDD"</tt> while <tt>values[:book].title</tt> returns
        # <tt>"No test"</tt>, the first will win.
        #
        # @param name [Symbol] the name of the form
        # @param url [String] the action of the form
        # @param values [Hash,NilClass] a Hash of values to be used to autofill
        #   `value` attributes for fields.
        # @param attributes [Hash,NilClass] a Hash of attributes to pass to the
        #   `form` tag
        #
        # @since 2.0.0
        #
        # @example Pass A Value
        #   # Given the following view
        #
        #   module Web::Views::Deliveries
        #     class Edit
        #       include Web::View
        #
        #       def form
        #         Form.new(:delivery, routes.delivery_path(id: delivery.id),
        #         {delivery: delivery, customer: customer},
        #         {method: :patch})
        #       end
        #     end
        #   end
        #
        #   # And the corresponding template:
        #
        #   <%=
        #     form_for form do
        #       date_field :delivered_on
        #
        #       fields_for :customer do
        #         text_field :name
        #
        #         fields_for :address do
        #           # ...
        #           text_field :city
        #         end
        #       end
        #
        #       submit 'Update'
        #     end
        #   %>
        #
        #   <!-- output -->
        #
        #   <form action="/deliveries/1" method="POST" accept-charset="utf-8">
        #     <input type="hidden" name="_method" value="PATCH">
        #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
        #
        #     # Value taken from delivery.delivered_on
        #     <input type="date" name="delivery[delivered_on]" id="delivery-delivered-on" value="2015-05-27">
        #
        #     # Value taken from customer.name
        #     <input type="text" name="delivery[customer][name]" id="delivery-customer-name" value="Luca">
        #
        #     # Value taken from customer.address.city
        #     <input type="text" name="delivery[customer][address][city]" id="delivery-customer-address-city" value="Rome">
        #
        #     <button type="submit">Update</button>
        #   </form>
        def initialize(name, url, values = {}, attributes = {})
          @name       = name
          @url        = url
          @values     = values
          @attributes = attributes || {}
        end

        # Return the method specified by the given attributes or fall back to
        # the default value
        #
        # @return [String] the method for the action
        #
        # @since 2.0.0
        # @api private
        #
        # @see Hanami::Helpers::FormHelper::DEFAULT_METHOD
        def verb
          @attributes.fetch(:method, DEFAULT_METHOD)
        end
      end

      # Instantiate a HTML5 form builder
      #
      # @param name [Symbol] the toplevel name of the form, it's used to generate
      #   input names, ids, and to lookup params to fill values.
      # @param url [String] the form action URL
      # @param values [Hash] An optional data payload to fill in form values
      #   It is passed automatically by Hanami, using view's `locals`
      # @option attributes [Hash] HTML attributes to pass to the form tag and form values
      # @param blk [Proc] A block that describes the contents of the form
      #
      # @return [Hanami::Helpers::FormHelper::FormBuilder] the form builder
      #
      # @since 2.0.0
      #
      # @see Hanami::Helpers::FormHelper
      # @see Hanami::Helpers::FormHelper::Form
      # @see Hanami::Helpers::FormHelper::FormBuilder
      #
      # @example Inline Values In Template
      #   <%= form_for(routes.books_path, class: "form-horizontal") do |f| %>
      #     <div>
      #       <%= f.label "book.title" %>
      #       <%= f.text_field "book.title", class: "form-control" %>
      #     </div>
      #
      #     <div>
      #       <%= f.submit "Create" %>
      #     </div>
      #   <% end %>
      #
      #   <!-- output -->
      #
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
      #
      #
      # @example Use In A View
      #
      #   module Web::Views::Books
      #     class New
      #
      #     def form
      #       form_for :book, routes.books_path, class: 'form-horizontal' do
      #         div do
      #           label      :title
      #           text_field :title, class: 'form-control'
      #         end
      #
      #         submit 'Create'
      #       end
      #     end
      #   end
      #
      #   <!-- in the corresponding template use this -->
      #   <%= form %>
      #
      #   <!-- output -->
      #
      #   <form action="/books" method="POST" accept-charset="utf-8" id="book-form" class="form-horizontal">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <div>
      #       <label for="book-title">Title</label>
      #       <input type="text" name="book[title]" id="book-title" value="Test Driven Development">
      #     </div>
      #
      #     <button type="submit">Create</button>
      #   </form>
      #
      # @example Share Code Between Views
      #
      #   # Given the following views to create and update a resource
      #   module Web::Views::Books
      #     class New
      #       include Web::View
      #
      #       def form
      #         Form.new(:book, routes.books_path)
      #       end
      #
      #       def submit_label
      #         'Create'
      #       end
      #     end
      #
      #     class Edit
      #       include Web::View
      #
      #       def form
      #         Form.new(:book, routes.book_path(id: book.id),
      #           {book: book}, {method: :patch})
      #       end
      #
      #       def submit_label
      #         'Update'
      #       end
      #     end
      #   end
      #
      #   # The respective templates can be identical:
      #
      #   ## books/new.html.erb
      #   <%= render partial: 'books/form' %>
      #
      #   ## books/edit.html.erb
      #   <%= render partial: 'books/form' %>
      #
      #   # While the partial can have the following markup:
      #
      #   ## books/_form.html.erb
      #   <%=
      #     form_for form, class: 'form-horizontal' do
      #       div do
      #         label      :title
      #         text_field :title, class: 'form-control'
      #       end
      #
      #       submit submit_label
      #     end
      #   %>
      #
      #   <!-- output -->
      #
      #   <form action="/books" method="POST" accept-charset="utf-8" id="book-form" class="form-horizontal">
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
      #   <%=
      #     form_for(routes.book_path(id: book.id), method: :put) do |f|
      #       f.text_field "book.title"
      #
      #       f.submit "Update"
      #     end
      #   %>
      #
      #   <!-- output -->
      #
      #   <form action="/books/23" accept-charset="utf-8" id="book-form" method="POST">
      #     <input type="hidden" name="_method" value="PUT">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <input type="text" name="book[title]" id="book-title" value="Test Driven Development">
      #
      #     <button type="submit">Update</button>
      #   </form>
      #
      # @example Nested fields
      #   <%=
      #     form_for routes.deliveries_path do |f|
      #       f.text_field "delivery.customer_name"
      #
      #       f.text_field "delivery.address.city"
      #
      #       f.submit "Create"
      #     end
      #   %>
      #
      #   <!-- output -->
      #
      #   <form action="/deliveries" accept-charset="utf-8" id="delivery-form" method="POST">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <input type="text" name="delivery[customer_name]" id="delivery-customer-name" value="">
      #     <input type="text" name="delivery[address][city]" id="delivery-address-city" value="">
      #
      #     <button type="submit">Create</button>
      #   </form>
      #
      # @example Override params
      #   <%=
      #     form_for(routes.songs_path, values: {params:{song:{title: "Envision"}}}) do |f|
      #       f.text_field "song.title"
      #
      #       f.submit "Create"
      #     end
      #   %>
      #
      #   <!-- output -->
      #
      #   <form action="/songs" accept-charset="utf-8" method="POST">
      #     <input type="hidden" name="_csrf_token" value="920cd5bfaecc6e58368950e790f2f7b4e5561eeeab230aa1b7de1b1f40ea7d5d">
      #     <input type="text" name="song[title]" id="song-title" value="Envision">
      #
      #     <button type="submit">Create</button>
      #   </form>
      def form_for(url, values: _form_for_values, params: _form_for_params, **attributes)
        attributes[:action] = url

        values = Values.new(values: values, params: params, csrf_token: _context.csrf_token)
        builder = FormBuilder.new(values: values, inflector: _context.inflector)

        content = (block_given? ? yield(builder) : "").html_safe

        builder.call(content, **attributes)
      end

      # @api private
      # @since 2.0.0
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
      # @since 2.0.0
      def _form_for_params
        _context.request.params
      end

      # Prints CSRF meta tags for Unobtrusive JavaScript (UJS) purposes.
      #
      # @return [Hanami::Helpers::HtmlHelper::HtmlBuilder,NilClass] the tags if `csrf_token` is not `nil`
      #
      # @since 2.0.0
      #
      # @example
      #   <html>
      #     <head>
      #       <!-- ... -->
      #       <%= csrf_meta_tags %>
      #     </head>
      #     <!-- ... -->
      #   </html>
      #
      #   <html>
      #     <head>
      #       <!-- ... -->
      #       <meta name="csrf-param" content="_csrf_token">
      #       <meta name="csrf-token" content="4a038be85b7603c406dcbfad4b9cdf91ec6ca138ed6441163a07bb0fdfbe25b5">
      #     </head>
      #     <!-- ... -->
      #   </html>
      def csrf_meta_tags
        return unless _context.csrf_token

        html.meta(name: "csrf-param", content: CSRF_TOKEN) +
          html.meta(name: "csrf-token", content: _context.csrf_token)
      end
    end
  end
end
