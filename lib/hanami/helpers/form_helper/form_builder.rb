# frozen_string_literal: true

require "dry-inflector"
require "hanami/view/helpers/escape_helper"
require_relative "values"

module Hanami
  module Helpers
    module FormHelper
      # Form builder
      #
      # @since 2.0.0
      #
      # @see Hanami::Helpers::HtmlHelper::HtmlBuilder
      class FormBuilder
        # Set of HTTP methods that are understood by web browsers
        #
        # @since 2.0.0
        # @api private
        BROWSER_METHODS = %w[GET POST].freeze
        private_constant :BROWSER_METHODS

        # Set of HTTP methods that should NOT generate CSRF token
        #
        # @since 2.0.0
        # @api private
        EXCLUDED_CSRF_METHODS = %w[GET].freeze
        private_constant :EXCLUDED_CSRF_METHODS

        # Separator for accept attribute of file input
        #
        # @since 2.0.0
        # @api private
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#file_input
        ACCEPT_SEPARATOR = ","
        private_constant :ACCEPT_SEPARATOR

        # Default value for unchecked check box
        #
        # @since 2.0.0
        # @api private
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#check_box
        DEFAULT_UNCHECKED_VALUE = "0"
        private_constant :DEFAULT_UNCHECKED_VALUE

        # Default value for checked check box
        #
        # @since 2.0.0
        # @api private
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#check_box
        DEFAULT_CHECKED_VALUE = "1"
        private_constant :DEFAULT_CHECKED_VALUE

        # Input name separator
        #
        # @since 2.0.0
        # @api private
        INPUT_NAME_SEPARATOR = "."
        private_constant :INPUT_NAME_SEPARATOR

        # Empty string
        #
        # @since 2.0.0
        # @api private
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#password_field
        EMPTY_STRING = ""
        private_constant :EMPTY_STRING

        include Hanami::View::Helpers::EscapeHelper
        include Hanami::View::Helpers::TagHelper

        # @api private
        # @since 2.0.0
        attr_reader :base_name
        private :base_name

        # @api private
        # @since 2.0.0
        attr_reader :inflector
        private :inflector

        # Instantiate a new form builder
        #
        # @param html [Hanami::Helpers::HtmlHelper::HtmlBuilder] an HTML builder
        # @param values [Hanami::Helpers::HtmlHelper::Values] form values
        # @param inflector [Dry::Inflector] string inflector
        # @param attributes [Hash] HTML attributes for the `<form>` tag
        # @param blk [Proc] the block to build the form
        #
        # @return [Hanami::Helpers::FormHelper::FormBuilder]
        #
        # @api private
        # @since 2.0.0
        def initialize(inflector:, base_name: nil, values: Values.new)
          @base_name = base_name
          @values = values
          @inflector = inflector
        end

        # @api public
        # @since 2.0.0
        def fields_for(name, value = nil)
          prev_base_name = @base_name
          @base_name = [@base_name, name.to_s].compact.join(INPUT_NAME_SEPARATOR)

          yield(name, value)
        ensure
          @base_name = prev_base_name
        end

        # @api public
        # @since 2.0.0
        def fields_for_collection(name, &block)
          collection = _value(name)

          prev_base_name = @base_name
          @base_name = [@base_name, name.to_s].compact.join(INPUT_NAME_SEPARATOR)

          collection.each_with_index do |value, index|
            fields_for(index, value, &block)
          end
        ensure
          @base_name = prev_base_name
        end

        # @api private
        # @since 2.0.0
        def call(content, **attributes)
          attributes["accept-charset"] ||= DEFAULT_CHARSET

          method_override, original_form_method = _form_method(attributes)
          csrf_token, token = _csrf_token(@values, attributes)

          tag.form(**attributes) do
            (+"").tap { |inner|
              inner << input(type: "hidden", name: "_method", value: original_form_method) if method_override
              inner << input(type: "hidden", name: "_csrf_token", value: token) if csrf_token
              inner << content
            }.html_safe
          end
        end

        # Label tag
        #
        # The first param (`content`) MUST be a `String` that indicates the
        # target field (e.g. `"book.extended_title"`).
        #
        # @param content [String] the field name
        # @param attributes [Hash] HTML attributes to pass to the label tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.label "book.extended_title"
        #   %>
        #
        #   <!-- output -->
        #   <label for="book-extended-title">Extended title</label>
        #
        # @example HTML attributes
        #   <%=
        #     # ...
        #     f.label "book.title", class: "form-label"
        #   %>
        #
        #   <!-- output -->
        #   <label for="book-title" class="form-label">Title</label>
        #
        # @example Custom content
        #   <%=
        #     # ...
        #     f.label "Title", for: "book.extended_title"
        #   %>
        #
        #   <!-- output -->
        #   <label for="book-extended-title">Title</label>
        #
        # @example Custom "for" attribute
        #   <%=
        #     # ...
        #     f.label "book.extended_title", for: "ext-title"
        #   %>
        #
        #   <!-- output -->
        #   <label for="ext-title">Extended title</label>
        #
        # @example Block syntax
        #   <%=
        #     # ...
        #     f.label for: "book.free_shipping" do
        #       f.text "Free shipping"
        #       f.abbr "*", title: "optional", "aria-label": "optional"
        #     end
        #   %>
        #
        #   <!-- output -->
        #   <label for="book-free-shipping">
        #     Free Shipping
        #     <abbr title="optional" aria-label="optional">*</abbr>
        #   </label>
        def label(content = nil, **attributes, &blk)
          for_attribute_given = attributes.key?(:for)

          attributes[:for] = _for(content, attributes[:for])
          if content && !for_attribute_given
            content = inflector.humanize(content.split(INPUT_NAME_SEPARATOR).last)
          end

          tag.label(content, **attributes, &blk)
        end

        # Fieldset
        #
        # @param content [String,NilClass] the content
        # @param attributes [Hash] HTML attributes to pass to the label tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.fieldset do
        #       f.legend "Author"
        #
        #       f.label "author.name"
        #       f.text_field "author.name"
        #     end
        #   %>
        #
        #   <!-- output -->
        #   <fieldset>
        #     <legend>Author</legend>
        #     <label for="book-author-name">Name</label>
        #     <input type="text" name="book[author][name]" id="book-author-name" value="">
        #   </fieldset>
        def fieldset(...)
          # This is here only for documentation purposes
          tag.fieldset(...)
        end

        # Check box
        #
        # It renders a check box input.
        #
        # When a form is submitted, browsers don"t send the value of unchecked
        # check boxes. If an user unchecks a check box, their browser won"t send
        # the unchecked value. On the server side the corresponding value is
        # missing, so the application will assume that the user action never
        # happened.
        #
        # To solve this problem the form renders a hidden field with the
        # "unchecked value". When the user unchecks the input, the browser will
        # ignore it, but it will still send the value of the hidden input. See
        # the examples below.
        #
        # When editing a resource, the form automatically assigns the
        # `checked` HTML attribute.
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        # @option attributes [String] :checked_value (defaults to "1")
        # @option attributes [String] :unchecked_value (defaults to "0")
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     f.check_box "delivery.free_shipping"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1">
        #
        # @example HTML Attributes
        #   <%=
        #     f.check_box "delivery.free_shipping", class: "form-check-input"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" class="form-check-input">
        #
        # @example Specify (un)checked values
        #   <%=
        #     f.check_box "delivery.free_shipping", checked_value: "true", unchecked_value: "false"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[free_shipping]" value="false">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="true">
        #
        # @example Automatic "checked" attribute
        #   # For this example the params are:
        #   #
        #   #  { delivery: { free_shipping: "1" } }
        #   <%=
        #     f.check_box "delivery.free_shipping"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" checked>
        #
        # @example Force "checked" attribute
        #   # For this example the params are:
        #   #
        #   #  { delivery: { free_shipping: "0" } }
        #   <%=
        #     f.check_box "deliver.free_shipping", checked: "checked"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" checked>
        #
        # @example Multiple check boxes
        #   <%=
        #     f.check_box "book.languages", name: "book[languages][]", value: "italian", id: nil
        #     f.check_box "book.languages", name: "book[languages][]", value: "english", id: nil
        #   %>
        #
        #   <!-- output -->
        #   <input type="checkbox" name="book[languages][]" value="italian">
        #   <input type="checkbox" name="book[languages][]" value="english">
        #
        # @example Automatic "checked" attribute for multiple check boxes
        #   # For this example the params are:
        #   #
        #   #  { book: { languages: ["italian"] } }
        #   <%=
        #     f.check_box "book.languages", name: "book[languages][]", value: "italian", id: nil
        #     f.check_box "book.languages", name: "book[languages][]", value: "english", id: nil
        #   %>
        #
        #   <!-- output -->
        #   <input type="checkbox" name="book[languages][]" value="italian" checked>
        #   <input type="checkbox" name="book[languages][]" value="english">
        def check_box(name, **attributes)
          (+"").tap { |output|
            output << _hidden_field_for_check_box(name, attributes).to_s
            output << input(**_attributes_for_check_box(name, attributes))
          }.html_safe
        end

        # Color input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.color_field "user.background"
        #   %>
        #
        #   <!-- output -->
        #   <input type="color" name="user[background]" id="user-background" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.color_field "user.background", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="color" name="user[background]" id="user-background" value="" class="form-control">
        def color_field(name, **attributes)
          input(**_attributes(:color, name, attributes))
        end

        # Date input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.date_field "user.birth_date"
        #   %>
        #
        #   <!-- output -->
        #   <input type="date" name="user[birth_date]" id="user-birth-date" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.date_field "user.birth_date", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="date" name="user[birth_date]" id="user-birth-date" value="" class="form-control">
        def date_field(name, **attributes)
          input(**_attributes(:date, name, attributes))
        end

        # Datetime input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.datetime_field "delivery.delivered_at"
        #   %>
        #
        #   <!-- output -->
        #   <input type="datetime" name="delivery[delivered_at]" id="delivery-delivered-at" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.datetime_field "delivery.delivered_at", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="datetime" name="delivery[delivered_at]" id="delivery-delivered-at" value="" class="form-control">
        def datetime_field(name, **attributes)
          input(**_attributes(:datetime, name, attributes))
        end

        # Datetime Local input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.datetime_local_field "delivery.delivered_at"
        #   %>
        #
        #   <!-- output -->
        #   <input type="datetime-local" name="delivery[delivered_at]" id="delivery-delivered-at" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.datetime_local_field "delivery.delivered_at", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="datetime-local" name="delivery[delivered_at]" id="delivery-delivered-at" value="" class="form-control">
        def datetime_local_field(name, **attributes)
          input(**_attributes(:"datetime-local", name, attributes))
        end

        # Time field
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.time_field "book.release_hour"
        #   %>
        #
        #   <!-- output -->
        #   <input type="time" name="book[release_hour]" id="book-release-hour" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.time_field "book.release_hour", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="time" name="book[release_hour]" id="book-release-hour" value="" class="form-control">
        def time_field(name, **attributes)
          input(**_attributes(:time, name, attributes))
        end

        # Month field
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.month_field "book.release_month"
        #   %>
        #
        #   <!-- output -->
        #   <input type="month" name="book[release_month]" id="book-release-month" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.month_field "book.release_month", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="month" name="book[release_month]" id="book-release-month" value="" class="form-control">
        def month_field(name, **attributes)
          input(**_attributes(:month, name, attributes))
        end

        # Week field
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.week_field "book.release_week"
        #   %>
        #
        #   <!-- output -->
        #   <input type="week" name="book[release_week]" id="book-release-week" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.week_field "book.release_week", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="week" name="book[release_week]" id="book-release-week" value="" class="form-control">
        def week_field(name, **attributes)
          input(**_attributes(:week, name, attributes))
        end

        # Email input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.email_field "user.email"
        #   %>
        #
        #   <!-- output -->
        #   <input type="email" name="user[email]" id="user-email" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.email_field "user.email", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="email" name="user[email]" id="user-email" value="" class="form-control">
        def email_field(name, **attributes)
          input(**_attributes(:email, name, attributes))
        end

        # URL input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.url_field "user.website"
        #   %>
        #
        #   <!-- output -->
        #   <input type="url" name="user[website]" id="user-website" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.url_field "user.website", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="url" name="user[website]" id="user-website" value="" class="form-control">
        def url_field(name, **attributes)
          attrs         = attributes.dup
          attrs[:value] = sanitize_url(attrs.fetch(:value) { _value(name) })

          input(**_attributes(:url, name, attrs))
        end

        # Telephone input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.tel_field "user.telephone"
        #   %>
        #
        #   <!-- output -->
        #   <input type="tel" name="user[telephone]" id="user-telephone" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.tel_field "user.telephone", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="tel" name="user[telephone]" id="user-telephone" value="" class="form-control">
        def tel_field(name, **attributes)
          input(**_attributes(:tel, name, attributes))
        end

        # Hidden input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.hidden_field "delivery.customer_id"
        #   %>
        #
        #   <!-- output -->
        #   <input type="hidden" name="delivery[customer_id]" id="delivery-customer-id" value="">
        def hidden_field(name, **attributes)
          input(**_attributes(:hidden, name, attributes))
        end

        # File input
        #
        # **PLEASE REMEMBER TO ADD `enctype: "multipart/form-data"` ATTRIBUTE TO THE FORM**
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        # @option attributes [String,Array] :accept Optional set of accepted MIME Types
        # @option attributes [TrueClass,FalseClass] :multiple Optional, allow multiple file upload
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.file_field "user.avatar"
        #   %>
        #
        #   <!-- output -->
        #   <input type="file" name="user[avatar]" id="user-avatar">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.file_field "user.avatar", class: "avatar-upload"
        #   %>
        #
        #   <!-- output -->
        #   <input type="file" name="user[avatar]" id="user-avatar" class="avatar-upload">
        #
        # @example Accepted MIME Types
        #   <%=
        #     # ...
        #     f.file_field "user-resume", accept: "application/pdf,application/ms-word"
        #   %>
        #
        #   <!-- output -->
        #   <input type="file" name="user[resume]" id="user-resume" accept="application/pdf,application/ms-word">
        #
        # @example Accepted MIME Types (as array)
        #   <%=
        #     # ...
        #     f.file_field "user.resume", accept: ["application/pdf", "application/ms-word"]
        #   %>
        #
        #   <!-- output -->
        #   <input type="file" name="user[resume]" id="user-resume" accept="application/pdf,application/ms-word">
        #
        # @example Accepted multiple file upload (as array)
        #   <%=
        #     # ...
        #     f.file_field "user.resume", multiple: true
        #   %>
        #
        #   <!-- output -->
        #   <input type="file" name="user[resume]" id="user-resume" multiple="multiple">
        def file_field(name, **attributes)
          attributes[:accept] = Array(attributes[:accept]).join(ACCEPT_SEPARATOR) if attributes.key?(:accept)
          attributes = {type: :file, name: _displayed_input_name(name), id: _input_id(name)}.merge(attributes)

          input(**attributes)
        end

        # Number input
        #
        # You can also make use of the `max`, `min`, and `step` attributes for
        # the HTML5 number field.
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the number input
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.number_field "book.percent_read"
        #   %>
        #
        #   <!-- output -->
        #   <input type="number" name="book[percent_read]" id="book-percent-read" value="">
        #
        # @example Advanced attributes
        #   <%=
        #     # ...
        #     f.number_field "book.percent_read", min: 1, max: 100, step: 1
        #   %>
        #
        #   <!-- output -->
        #   <input type="number" name="book[percent_read]" id="book-precent-read" value="" min="1" max="100" step="1">
        def number_field(name, **attributes)
          input(**_attributes(:number, name, attributes))
        end

        # Range input
        #
        # You can also make use of the `max`, `min`, and `step` attributes for
        # the HTML5 number field.
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the number input
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.range_field "book.discount_percentage"
        #   %>
        #
        #   <!-- output -->
        #   <input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="">
        #
        # @example Advanced attributes
        #   <%=
        #     # ...
        #     f.range_field "book.discount_percentage", min: 1, max: 1'0, step: 1
        #   %>
        #
        #   <!-- output -->
        #   <input type="number" name="book[discount_percentage]" id="book-discount-percentage" value="" min="1" max="100" step="1">
        def range_field(name, **attributes)
          input(**_attributes(:range, name, attributes))
        end

        # Text-area input
        #
        # @param name [String] the input name
        # @param content [String] the content of the textarea
        # @param attributes [Hash] HTML attributes to pass to the textarea tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.text_area "user.hobby"
        #   %>
        #
        #   <!-- output -->
        #   <textarea name="user[hobby]" id="user-hobby"></textarea>
        #
        # @example Set content
        #   <%=
        #     # ...
        #     f.text_area "user.hobby", "Football"
        #   %>
        #
        #   <!-- output -->
        #   <textarea name="user[hobby]" id="user-hobby">Football</textarea>
        #
        # @example Set content and HTML attributes
        #   <%=
        #     # ...
        #     f.text_area "user.hobby", "Football", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <textarea name="user[hobby]" id="user-hobby" class="form-control">Football</textarea>
        #
        # @example Omit content and specify HTML attributes
        #   <%=
        #     # ...
        #     f.text_area "user.hobby", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <textarea name="user[hobby]" id="user-hobby" class="form-control"></textarea>
        #
        # @example Force blank value
        #   <%=
        #     # ...
        #     f.text_area "user.hobby", "", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <textarea name="user[hobby]" id="user-hobby" class="form-control"></textarea>
        def text_area(name, content = nil, **attributes)
          if content.respond_to?(:to_hash)
            attributes = content
            content    = nil
          end

          attributes = {name: _displayed_input_name(name), id: _input_id(name)}.merge(attributes)
          tag.textarea(content || _value(name), **attributes)
        end

        # Text input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.text_field "user.first_name"
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="user[first_name]" id="user-first-name" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.text_field "user.first_name", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="user[first_name]" id="user-first-name" value="" class="form-control">
        def text_field(name, **attributes)
          input(**_attributes(:text, name, attributes))
        end
        alias_method :input_text, :text_field

        # Search input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.search_field "search.q"
        #   %>
        #
        #   <!-- output -->
        #   <input type="search" name="search[q]" id="search-q" value="">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.search_field "search.q", class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <input type="search" name="search[q]" id="search-q" value="" class="form-control">
        def search_field(name, **attributes)
          input(**_attributes(:search, name, attributes))
        end

        # Radio input
        #
        # If request params have a value that corresponds to the given value,
        # it automatically sets the `checked` attribute.
        # This `hanami-controller` integration happens without any developer intervention.
        #
        # @param name [String] the input name
        # @param value [String] the input value
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.radio_button "book.category", "Fiction"
        #     f.radio_button "book.category", "Non-Fiction"
        #   %>
        #
        #   <!-- output -->
        #   <input type="radio" name="book[category]" value="Fiction">
        #   <input type="radio" name="book[category]" value="Non-Fiction">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.radio_button "book.category", "Fiction", class: "form-check"
        #     f.radio_button "book.category", "Non-Fiction", class: "form-check"
        #   %>
        #
        #   <!-- output -->
        #   <input type="radio" name="book[category]" value="Fiction" class="form-check">
        #   <input type="radio" name="book[category]" value="Non-Fiction" class="form-check">
        #
        # @example Automatic checked value
        #   # Given the following params:
        #   #
        #   # book: {
        #   #   category: "Non-Fiction"
        #   # }
        #
        #   <%=
        #     # ...
        #     f.radio_button "book.category", "Fiction"
        #     f.radio_button "book.category", "Non-Fiction"
        #   %>
        #
        #   <!-- output -->
        #   <input type="radio" name="book[category]" value="Fiction">
        #   <input type="radio" name="book[category]" value="Non-Fiction" checked>
        def radio_button(name, value, **attributes)
          attributes = {type: :radio, name: _displayed_input_name(name), value: value}.merge(attributes)
          attributes[:checked] = true if _value(name).to_s == value.to_s

          input(**attributes)
        end

        # Password input
        #
        # @param name [String] the input name
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.password_field "signup.password"
        #   %>
        #
        #   <!-- output -->
        #   <input type="password" name="signup[password]" id="signup-password" value="">
        def password_field(name, **attributes)
          attrs = {type: :password, name: _displayed_input_name(name), id: _input_id(name), value: nil}.merge(attributes)
          attrs[:value] = EMPTY_STRING if attrs[:value].nil?

          input(**attrs)
        end

        # Select input
        #
        # @param name [String] the input name
        # @param values [Hash] a Hash to generate `<option>` tags.
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # Values is used to generate the list of `<option>` tags, it is an
        # `Enumerable` of pairs of content (the displayed text) and value (the tag's
        # attribute), in that respective order (please refer to the examples for more clarity).
        #
        # If request params have a value that corresponds to one of the given values,
        # it automatically sets the `selected` attribute on the `<option>` tag.
        # This `hanami-controller` integration happens without any developer intervention.
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store">
        #     <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values, class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store" class="form-control">
        #     <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Automatic selected option
        #   # Given the following params:
        #   #
        #   # book: {
        #   #   store: "it"
        #   # }
        #
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store">
        #     <option value="it" selected="selected">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Prompt option
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values, options: { prompt: "Select a store" }
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store">
        #     <option>Select a store</option>
        #     <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Selected option
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values, options: { selected: book.store }
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store">
        #     <option value="it" selected="selected">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Prompt option and HTML attributes
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.store", values, options: { prompt: "Select a store" }, class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store" class="form-control">
        #     <option disabled="disabled">Select a store</option>
        #     <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Multiple select
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.stores", values, multiple: true
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store][]" id="book-store" multiple="multiple">
        #    <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Multiple select and HTML attributes
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.select "book.stores", values, multiple: true, class: "form-control"
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store][]" id="book-store" multiple="multiple" class="form-control">
        #     <option value="it">Italy</option>
        #     <option value="us">United States</option>
        #   </select>
        #
        # @example Array with repeated entries
        #   <%=
        #     # ...
        #     values = [["Italy", "it"],
        #               ["---", ""],
        #               ["Afghanistan", "af"],
        #               ...
        #               ["Italy", "it"],
        #               ...
        #               ["Zimbabwe", "zw"]]
        #     f.select "book.stores", values
        #   %>
        #
        #   <!-- output -->
        #   <select name="book[store]" id="book-store">
        #     <option value="it">Italy</option>
        #     <option value="">---</option>
        #     <option value="af">Afghanistan</option>
        #     ...
        #     <option value="it">Italy</option>
        #     ...
        #     <option value="zw">Zimbabwe</option>
        #   </select>
        def select(name, values, **attributes) # rubocop:disable Metrics/AbcSize
          options     = attributes.delete(:options) { {} }
          multiple    = attributes[:multiple]
          attributes  = {name: _select_input_name(name, multiple), id: _input_id(name), **attributes}
          prompt      = options.delete(:prompt)
          selected    = options.delete(:selected)
          input_value = _value(name)

          option_tags = []
          option_tags << tag.option(prompt, disabled: true) if prompt

          already_selected = nil
          values.each do |content, value|
            if (multiple || !already_selected) &&
               (already_selected = _select_option_selected?(value, selected, input_value, multiple))
              option_tags << tag.option(content, value: value, selected: true, **options)
            else
              option_tags << tag.option(content, value: value, **options)
            end
          end

          tag.select(option_tags.join.html_safe, **attributes)
        end

        # Datalist input
        #
        # @param name [String] the input name
        # @param values [Array,Hash] a collection that is transformed into <tt><option></tt> tags.
        # @param list [String] the name of list for the text input, it"s also the id of datalist
        # @param attributes [Hash] HTML attributes to pass to the input tag
        #
        # @since 2.0.0
        #
        # @example Basic Usage
        #   <%=
        #     # ...
        #     values = ["Italy", "United States"]
        #     f.datalist "book.stores", values, "books"
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy"></option>
        #     <option value="United States"></option>
        #   </datalist>
        #
        # @example Options As Hash
        #   <%=
        #     # ...
        #     values = Hash["Italy" => "it", "United States" => "us"]
        #     f.datalist "book.stores", values, "books"
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy">it</option>
        #     <option value="United States">us</option>
        #   </datalist>
        #
        # @example Specify Custom Attributes For Datalist Input
        #   <%=
        #     # ...
        #     values = ["Italy", "United States"]
        #     f.datalist "book.stores", values, "books", datalist: { class: "form-control" }
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books" class="form-control">
        #     <option value="Italy"></option>
        #     <option value="United States"></option>
        #   </datalist>
        #
        # @example Specify Custom Attributes For Options List
        #   <%=
        #     # ...
        #     values = ["Italy", "United States"]
        #     f.datalist "book.stores", values, "books", options: { class: "form-control" }
        #   %>
        #
        #   <!-- output -->
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy" class="form-control"></option>
        #     <option value="United States" class="form-control"></option>
        #   </datalist>
        def datalist(name, values, list, **attributes)
          attrs    = attributes.dup
          options  = attrs.delete(:options)  || {}
          datalist = attrs.delete(:datalist) || {}

          attrs[:list]  = list
          datalist[:id] = list

          (+"").tap { |output|
            output << text_field(name, **attrs)
            output << tag.datalist(**datalist) {
              (+"").tap { |inner|
                values.each do |value, content|
                  inner << tag.option(content, **{value: value}.merge(options))
                end
              }.html_safe
            }
          }.html_safe
        end

        # Button
        #
        # @overload button(content, **attributes)
        #   Use string content
        #   @param content [String] The content
        #   @param attributes [Hash] HTML attributes to pass to the button tag
        #
        # @overload button(**attributes, &blk)
        #   Use block content
        #   @param attributes [Hash] HTML attributes to pass to the button tag
        #   @param blk [Proc] the block content
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.button "Click me"
        #   %>
        #
        #   <!-- output -->
        #   <button>Click me</button>
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.button "Click me", class: "btn btn-secondary"
        #   %>
        #
        #   <!-- output -->
        #   <button class="btn btn-secondary">Click me</button>
        #
        # @example Block
        #   <%=
        #     # ...
        #     f.button class: "btn btn-secondary" do
        #       f.span class: "oi oi-check"
        #     end
        #   %>
        #
        #   <!-- output -->
        #   <button class="btn btn-secondary">
        #     <span class="oi oi-check"></span>
        #   </button>
        def button(...)
          tag.button(...)
        end

        # Image button
        #
        # Visual submit button
        #
        # **Please note:** for security reasons, please use the absolute URL of the image
        #
        # @param source [String] The **absolute URL** of the image
        # @param attributes [Hash] HTML attributes to pass to the button tag
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.image_button "https://hanamirb.org/assets/button.png"
        #   %>
        #
        #   <!-- output -->
        #   <input type="image" src="https://hanamirb.org/assets/button.png">
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.image_button "https://hanamirb.org/assets/button.png", name: "image", width: "50"
        #   %>
        #
        #   <!-- output -->
        #   <input name="image" width="50" type="image" src="https://hanamirb.org/assets/button.png">
        def image_button(source, **attributes)
          attributes[:type] = :image
          attributes[:src]  = sanitize_url(source)

          input(**attributes)
        end

        # Submit button
        #
        # @overload submit(content, **attributes)
        #   Use string content
        #   @param content [String] The content
        #   @param attributes [Hash] HTML attributes to pass to the button tag
        #
        # @overload submit(**attributes, &blk)
        #   Use block content
        #   @param attributes [Hash] HTML attributes to pass to the button tag
        #   @param blk [Proc] the block content
        #
        # @since 2.0.0
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.submit "Create"
        #   %>
        #
        #   <!-- output -->
        #   <button type="submit">Create</button>
        #
        # @example HTML Attributes
        #   <%=
        #     # ...
        #     f.submit "Create", class: "btn btn-primary"
        #   %>
        #
        #   <!-- output -->
        #   <button type="submit" class="btn btn-primary">Create</button>
        #
        # @example Block
        #   <%=
        #     # ...
        #     f.submit class: "btn btn-primary" do
        #       f.span class: "oi oi-check"
        #     end
        #   %>
        #
        #   <!-- output -->
        #   <button type="submit" class="btn btn-primary">
        #     <span class="oi oi-check"></span>
        #   </button>
        def submit(content = nil, **attributes, &blk)
          if content.is_a?(::Hash)
            attributes = content
            content = nil
          end

          attributes = {type: :submit}.merge(attributes)
          tag.button(content, **attributes, &blk)
        end

        # Form input
        #
        # It generates markup for the given HTML attributes.
        # For advanced features, please use the other methods of form builder.
        #
        # @param attributes [Hash] HTML attributes
        # @param blk [Proc] optional block for nested costants
        #
        # @since 2.0.0
        # @api public
        #
        # @example Basic usage
        #   <%=
        #     # ...
        #     f.input(type: :text, name: "book[title]", id: "book-title", value: book.title)
        #   %>
        #   <!-- output -->
        #   <input type="text" name="book[title]" id="book-title" value="Hanami book">
        def input(...)
          tag.input(...)
        end

        private

        # @api private
        # @since 2.0.0
        def _form_method(attributes)
          attributes[:method] ||= DEFAULT_METHOD
          attributes[:method] = attributes[:method].to_s.upcase

          original_form_method = attributes[:method]

          if (method_override = !BROWSER_METHODS.include?(attributes[:method]))
            attributes[:method] = DEFAULT_METHOD
          end

          [method_override, original_form_method]
        end

        # @api private
        # @since 2.0.0
        def _csrf_token(values, attributes)
          return [] if values.csrf_token.nil?

          return [] if EXCLUDED_CSRF_METHODS.include?(attributes[:method])

          [true, values.csrf_token]
        end

        # Return a set of default HTML attributes
        #
        # @api private
        # @since 2.0.0
        def _attributes(type, name, attributes)
          # input_name = _input_name(name)

          attrs = {
            type: type,
            name: _displayed_input_name(name),
            id: _input_id(name),
            value: _value_from_input_name(_input_name(name))
          }
          attrs.merge!(attributes)
          attrs[:value] = escape_html(attrs[:value])
          attrs
        end

        # Full input name, used to construct the input
        # attributes.
        #
        # @api private
        # @since 2.0.0
        def _input_name(name)
          token, *tokens = [*base_name.to_s.split(INPUT_NAME_SEPARATOR), *name.to_s.split(INPUT_NAME_SEPARATOR)].compact
          result = String.new(token)

          tokens.each do |t|
            result << "[#{t}]"
          end

          result
        end

        def _displayed_input_name(name)
          _input_name(name).gsub(/\[\d+\]/, "[]")
        end

        # Input <tt>id</tt> HTML attribute
        #
        # @api private
        # @since 2.0.0
        def _input_id(name)
          [base_name, name].compact.join(INPUT_NAME_SEPARATOR).to_s.tr("._", "-")
        end

        # Input <tt>value</tt> HTML attribute
        #
        # @api private
        # @since 2.0.0
        def _value(name)
          _value_from_input_name(_input_name(name))
        end

        # Input <tt>value</tt> HTML attribute
        #
        # @api private
        # @since 2.0.0
        def _value_from_input_name(input_name)
          @values.get(
            *input_name.split(/[\[\]]+/).map(&:to_sym)
          )
        end

        # Input <tt>for</tt> HTML attribute
        #
        # @api private
        # @since 2.0.0
        def _for(content, name)
          _input_id(name || content)
        end

        # Hidden field for check box
        #
        # @api private
        # @since 2.0.0
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#check_box
        def _hidden_field_for_check_box(name, attributes)
          return unless attributes[:value].nil? || !attributes[:unchecked_value].nil?

          input(
            type: :hidden,
            name: attributes[:name] || _displayed_input_name(name),
            value: (attributes.delete(:unchecked_value) || DEFAULT_UNCHECKED_VALUE).to_s
          )
        end

        # HTML attributes for check box
        #
        # @api private
        # @since 2.0.0
        #
        # @see Hanami::Helpers::FormHelper::FormBuilder#check_box
        def _attributes_for_check_box(name, attributes)
          attributes = {
            type: :checkbox,
            name: _displayed_input_name(name),
            id: _input_id(name),
            value: (attributes.delete(:checked_value) || DEFAULT_CHECKED_VALUE).to_s
          }.merge(attributes)

          attributes[:checked] = true if _check_box_checked?(attributes[:value], _value(name))

          attributes
        end

        # @api private
        # @since 1.2.0
        def _select_input_name(name, multiple)
          select_name = _displayed_input_name(name)
          select_name = "#{select_name}[]" if multiple
          select_name
        end

        # @api private
        # @since 1.2.0
        def _select_option_selected?(value, selected, input_value, multiple)
          if input_value && selected.nil?
            value.to_s == input_value.to_s
          else
            (value == selected) ||
              _is_in_selected_values?(multiple, selected, value) ||
              _is_current_value?(input_value, value) ||
              _is_in_input_values?(multiple, input_value, value)
          end
        end

        # @api private
        # @since 1.2.0
        def _is_current_value?(input_value, value)
          return unless input_value

          value.to_s == input_value.to_s
        end

        # @api private
        # @since 1.2.0
        def _is_in_selected_values?(multiple, selected, value)
          return unless multiple && selected.is_a?(Array)

          selected.include?(value)
        end

        # @api private
        # @since 1.2.0
        def _is_in_input_values?(multiple, input_value, value)
          return unless multiple && input_value.is_a?(Array)

          input_value.include?(value)
        end

        # @api private
        # @since 1.2.0
        def _check_box_checked?(value, input_value)
          !input_value.nil? &&
            (input_value.to_s == value.to_s || input_value.is_a?(TrueClass) ||
            (input_value.is_a?(Array) && input_value.include?(value)))
        end
      end
    end
  end
end
