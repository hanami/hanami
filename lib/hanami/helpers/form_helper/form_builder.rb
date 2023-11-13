# frozen_string_literal: true

require "hanami/view"
require_relative "values"

module Hanami
  module Helpers
    module FormHelper
      # A range of convenient methods for building the fields within an HTML form, integrating with
      # request params and template locals to populate the fields with appropriate values.
      #
      # @see FormHelper#form_for
      #
      # @api public
      # @since 2.1.0
      class FormBuilder
        # Set of HTTP methods that are understood by web browsers
        #
        # @since 2.1.0
        # @api private
        BROWSER_METHODS = %w[GET POST].freeze
        private_constant :BROWSER_METHODS

        # Set of HTTP methods that should NOT generate CSRF token
        #
        # @since 2.1.0
        # @api private
        EXCLUDED_CSRF_METHODS = %w[GET].freeze
        private_constant :EXCLUDED_CSRF_METHODS

        # Separator for accept attribute of file input
        #
        # @since 2.1.0
        # @api private
        #
        # @see #file_input
        ACCEPT_SEPARATOR = ","
        private_constant :ACCEPT_SEPARATOR

        # Default value for unchecked check box
        #
        # @since 2.1.0
        # @api private
        #
        # @see #check_box
        DEFAULT_UNCHECKED_VALUE = "0"
        private_constant :DEFAULT_UNCHECKED_VALUE

        # Default value for checked check box
        #
        # @since 2.1.0
        # @api private
        #
        # @see #check_box
        DEFAULT_CHECKED_VALUE = "1"
        private_constant :DEFAULT_CHECKED_VALUE

        # Input name separator
        #
        # @since 2.1.0
        # @api private
        INPUT_NAME_SEPARATOR = "."
        private_constant :INPUT_NAME_SEPARATOR

        # Empty string
        #
        # @since 2.1.0
        # @api private
        #
        # @see #password_field
        EMPTY_STRING = ""
        private_constant :EMPTY_STRING

        include Hanami::View::Helpers::EscapeHelper
        include Hanami::View::Helpers::TagHelper

        # @api private
        # @since 2.1.0
        attr_reader :base_name
        private :base_name

        # @api private
        # @since 2.1.0
        attr_reader :values
        private :values

        # @api private
        # @since 2.1.0
        attr_reader :inflector
        private :inflector

        # @api private
        # @since 2.1.0
        attr_reader :form_attributes
        private :form_attributes

        # Returns a new form builder.
        #
        # @param inflector [Dry::Inflector] the app inflector
        # @param base_name [String, nil] the base name to use for all fields in the form
        # @param values [Hanami::Helpers::FormHelper::Values] the values for the form
        #
        # @return [self]
        #
        # @see Hanami::Helpers::FormHelper#form_for
        #
        # @api private
        # @since 2.1.0
        def initialize(inflector:, form_attributes:, base_name: nil, values: Values.new)
          @base_name = base_name
          @values = values
          @form_attributes = form_attributes
          @inflector = inflector
        end

        # @api private
        # @since 2.1.0
        def call(content, **attributes)
          attributes["accept-charset"] ||= DEFAULT_CHARSET

          method_override, original_form_method = _form_method(attributes)
          csrf_token, token = _csrf_token(values, attributes)

          tag.form(**attributes) do
            (+"").tap { |inner|
              inner << input(type: "hidden", name: "_method", value: original_form_method) if method_override
              inner << input(type: "hidden", name: "_csrf_token", value: token) if csrf_token
              inner << content
            }.html_safe
          end
        end

        # Applies the base input name to all fields within the given block.
        #
        # This can be helpful when generating a set of nested fields.
        #
        # This is a convenience only. You can achieve the same result by including the base name at
        # the beginning of each input name.
        #
        # @param name [String] the base name to be used for all fields in the block
        # @yieldparam [FormBuilder] the form builder for the nested fields
        #
        # @example Basic usage
        #   <% f.fields_for "address" do |fa| %>
        #     <%= fa.text_field "street" %>
        #     <%= fa.text_field "suburb" %>
        #   <% end %>
        #
        #   # A convenience for:
        #   # <%= f.text_field "address.street" %>
        #   # <%= f.text_field "address.suburb" %>
        #
        #   =>
        #   <input type="text" name="delivery[customer_name]" id="delivery-customer-name" value="">
        #   <input type="text" name="delivery[address][street]" id="delivery-address-street" value="">
        #
        # @example Multiple levels of nesting
        #   <% f.fields_for "address" do |fa| %>
        #     <%= fa.text_field "street" %>
        #
        #     <% fa.fields_for "location" do |fl| %>
        #       <%= fl.text_field "city" %>
        #     <% end %>
        #   <% end %>
        #
        #   =>
        #   <input type="text" name="delivery[address][street]" id="delivery-address-street" value="">
        #   <input type="text" name="delivery[address][location][city]" id="delivery-address-location-city" value="">
        #
        # @api public
        # @since 2.1.0
        def fields_for(name, *yield_args)
          new_base_name = [base_name, name.to_s].compact.join(INPUT_NAME_SEPARATOR)

          builder = self.class.new(
            base_name: new_base_name,
            values: values,
            form_attributes: form_attributes,
            inflector: inflector
          )

          yield(builder, *yield_args)
        end

        # Yields to the given block for each element in the matching collection value, and applies
        # the base input name to all fields within the block.
        #
        # Use this whenever generating form fields for an collection of nested fields.
        #
        # @param name [String] the input name, also used as the base input name for all fields
        #   within the block
        # @yieldparam [FormBuilder] the form builder for the nested fields
        # @yieldparam [Integer] the index of the iteration over the colletion, starting from zero
        # @yieldparam [Object] the value of the element from the collection
        #
        # @example Basic usage
        #   <% f.fields_for_collection("addresses") do |fa| %>
        #     <%= fa.text_field("street") %>
        #   <% end %>
        #
        #   =>
        #   <input type="text" name="delivery[addresses][][street]" id="delivery-address-0-street" value="">
        #   <input type="text" name="delivery[addresses][][street]" id="delivery-address-1-street" value="">
        #
        # @example Yielding index and value
        #   <% f.fields_for_collection("bill.addresses") do |fa, i, address| %>
        #     <div class="form-group">
        #       Address id: <%= address.id %>
        #       <%= fa.label("street") %>
        #       <%= fa.text_field("street", data: {index: i.to_s}) %>
        #     </div>
        #   <% end %>
        #
        #   =>
        #   <div class="form-group">
        #     Address id: 23
        #     <label for="bill-addresses-0-street">Street</label>
        #     <input type="text" name="bill[addresses][][street]" id="bill-addresses-0-street" value="5th Ave" data-index="0">
        #   </div>
        #   <div class="form-group">
        #     Address id: 42
        #     <label for="bill-addresses-1-street">Street</label>
        #     <input type="text" name="bill[addresses][][street]" id="bill-addresses-1-street" value="4th Ave" data-index="1">
        #   </div>
        #
        # @api public
        # @since 2.1.0
        def fields_for_collection(name, &block)
          collection_base_name = [base_name, name.to_s].compact.join(INPUT_NAME_SEPARATOR)

          _value(name).each_with_index do |value, index|
            fields_for("#{collection_base_name}.#{index}", index, value, &block)
          end
        end

        # Returns a label tag.
        #
        # @return [String] the tag
        #
        # @overload label(field_name, **attributes)
        #   Returns a label tag for the given field name, with a humanized version of the field name
        #   as the tag's content.
        #
        #   @param field_name [String] the field name
        #   @param attributes [Hash] the tag attributes
        #
        #   @example
        #     <%= f.label("book.extended_title") %>
        #     # => <label for="book-extended-title">Extended title</label>
        #
        #   @example HTML attributes
        #     <%= f.label("book.title", class: "form-label") %>
        #     # => <label for="book-title" class="form-label">Title</label>
        #
        # @overload label(content, **attributes)
        #   Returns a label tag for the field name given as `for:`, with the given content string as
        #   the tag's content.
        #
        #   @param content [String] the tag's content
        #   @param for [String] the field name
        #   @param attributes [Hash] the tag attributes
        #
        #   @example
        #     <%= f.label("Title", for: "book.extended_title") %>
        #     # => <label for="book-extended-title">Title</label>
        #
        #     f.label("book.extended_title", for: "ext-title")
        #     # => <label for="ext-title">Extended title</label>
        #
        # @overload label(field_name, **attributes, &block)
        #   Returns a label tag for the given field name, with the return value of the given block
        #   as the tag's content.
        #
        #   @param field_name [String] the field name
        #   @param attributes [Hash] the tag attributes
        #   @yieldreturn [String] the tag content
        #
        #   @example
        #     <%= f.label for: "book.free_shipping" do %>
        #       Free shipping
        #       <abbr title="optional" aria-label="optional">*</abbr>
        #     <% end %>
        #
        #     # =>
        #     <label for="book-free-shipping">
        #       Free shipping
        #       <abbr title="optional" aria-label="optional">*</abbr>
        #     </label>
        #
        # @api public
        # @since 2.1.0
        def label(content = nil, **attributes, &block)
          for_attribute_given = attributes.key?(:for)

          attributes[:for] = _input_id(attributes[:for] || content)

          if content && !for_attribute_given
            content = inflector.humanize(content.split(INPUT_NAME_SEPARATOR).last)
          end

          tag.label(content, **attributes, &block)
        end

        # @overload fieldset(**attributes, &block)
        #   Returns a fieldset tag.
        #
        #   @param attributes [Hash] the tag's HTML attributes
        #   @yieldreturn [String] the tag's content
        #
        #   @return [String] the tag
        #
        #   @example
        #     <%= f.fieldset do %>
        #       <%= f.legend("Author") %>
        #       <%= f.label("author.name") %>
        #       <%= f.text_field("author.name") %>
        #     <% end %>
        #
        #     # =>
        #     <fieldset>
        #       <legend>Author</legend>
        #       <label for="book-author-name">Name</label>
        #       <input type="text" name="book[author][name]" id="book-author-name" value="">
        #     </fieldset>
        #
        # @since 2.1.0
        # @api public
        def fieldset(...)
          # This is here only for documentation purposes
          tag.fieldset(...)
        end

        # Returns the tags for a check box.
        #
        # When editing a resource, the form automatically assigns the `checked` HTML attribute for
        # the check box tag.
        #
        # Returns a hidden input tag in preceding the check box input tag. This ensures that
        # unchecked values are submitted with the form.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the HTML attributes for the check box tag
        # @option attributes [String] :checked_value (defaults to "1")
        # @option attributes [String] :unchecked_value (defaults to "0")
        #
        # @return [String] the tags
        #
        # @example Basic usage
        #   f.check_box("delivery.free_shipping")
        #
        #   # =>
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1">
        #
        # @example HTML Attributes
        #   f.check_box("delivery.free_shipping", class: "form-check-input")
        #
        #   =>
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" class="form-check-input">
        #
        # @example Specifying checked and unchecked values
        #   f.check_box("delivery.free_shipping", checked_value: "true", unchecked_value: "false")
        #
        #   =>
        #   <input type="hidden" name="delivery[free_shipping]" value="false">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="true">
        #
        # @example Automatic "checked" attribute
        #   # Given the request params:
        #   # {delivery: {free_shipping: "1"}}
        #   f.check_box("delivery.free_shipping")
        #
        #   =>
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" checked="checked">
        #
        # @example Forcing the "checked" attribute
        #   # Given the request params:
        #   # {delivery: {free_shipping: "0"}}
        #   f.check_box("deliver.free_shipping", checked: "checked")
        #
        #   =>
        #   <input type="hidden" name="delivery[free_shipping]" value="0">
        #   <input type="checkbox" name="delivery[free_shipping]" id="delivery-free-shipping" value="1" checked="checked">
        #
        # @example Multiple check boxes for an array of values
        #   f.check_box("book.languages", name: "book[languages][]", value: "italian", id: nil)
        #   f.check_box("book.languages", name: "book[languages][]", value: "english", id: nil)
        #
        #   =>
        #   <input type="checkbox" name="book[languages][]" value="italian">
        #   <input type="checkbox" name="book[languages][]" value="english">
        #
        # @example Automatic "checked" attribute for an array of values
        #   # Given the request params:
        #   # {book: {languages: ["italian"]}}
        #   f.check_box("book.languages", name: "book[languages][]", value: "italian", id: nil)
        #   f.check_box("book.languages", name: "book[languages][]", value: "english", id: nil)
        #
        #   =>
        #   <input type="checkbox" name="book[languages][]" value="italian" checked="checked">
        #   <input type="checkbox" name="book[languages][]" value="english">
        #
        # @api public
        # @since 2.1.0
        def check_box(name, **attributes)
          (+"").tap { |output|
            output << _hidden_field_for_check_box(name, attributes).to_s
            output << input(**_attributes_for_check_box(name, attributes))
          }.html_safe
        end

        # Returns a color input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.color_field("user.background")
        #   => <input type="color" name="user[background]" id="user-background" value="">
        #
        # @example HTML Attributes
        #   f.color_field("user.background", class: "form-control")
        #   => <input type="color" name="user[background]" id="user-background" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def color_field(name, **attributes)
          input(**_attributes(:color, name, attributes))
        end

        # Returns a date input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.date_field("user.birth_date")
        #   # => <input type="date" name="user[birth_date]" id="user-birth-date" value="">
        #
        # @example HTML Attributes
        #   f.date_field("user.birth_date", class: "form-control")
        #   => <input type="date" name="user[birth_date]" id="user-birth-date" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def date_field(name, **attributes)
          input(**_attributes(:date, name, attributes))
        end

        # Returns a datetime input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.datetime_field("delivery.delivered_at")
        #   => <input type="datetime" name="delivery[delivered_at]" id="delivery-delivered-at" value="">
        #
        # @example HTML Attributes
        #   f.datetime_field("delivery.delivered_at", class: "form-control")
        #   => <input type="datetime" name="delivery[delivered_at]" id="delivery-delivered-at" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def datetime_field(name, **attributes)
          input(**_attributes(:datetime, name, attributes))
        end

        # Returns a datetime-local input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.datetime_local_field("delivery.delivered_at")
        #   => <input type="datetime-local" name="delivery[delivered_at]" id="delivery-delivered-at" value="">
        #
        # @example HTML Attributes
        #   f.datetime_local_field("delivery.delivered_at", class: "form-control")
        #   => <input type="datetime-local" name="delivery[delivered_at]" id="delivery-delivered-at" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def datetime_local_field(name, **attributes)
          input(**_attributes(:"datetime-local", name, attributes))
        end

        # Returns a time input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.time_field("book.release_hour")
        #   => <input type="time" name="book[release_hour]" id="book-release-hour" value="">
        #
        # @example HTML Attributes
        #   f.time_field("book.release_hour", class: "form-control")
        #   => <input type="time" name="book[release_hour]" id="book-release-hour" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def time_field(name, **attributes)
          input(**_attributes(:time, name, attributes))
        end

        # Returns a month input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.month_field("book.release_month")
        #   => <input type="month" name="book[release_month]" id="book-release-month" value="">
        #
        # @example HTML Attributes
        #   f.month_field("book.release_month", class: "form-control")
        #   => <input type="month" name="book[release_month]" id="book-release-month" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def month_field(name, **attributes)
          input(**_attributes(:month, name, attributes))
        end

        # Returns a week input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.week_field("book.release_week")
        #   => <input type="week" name="book[release_week]" id="book-release-week" value="">
        #
        # @example HTML Attributes
        #   f.week_field("book.release_week", class: "form-control")
        #   => <input type="week" name="book[release_week]" id="book-release-week" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def week_field(name, **attributes)
          input(**_attributes(:week, name, attributes))
        end

        # Returns an email input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.email_field("user.email")
        #   => <input type="email" name="user[email]" id="user-email" value="">
        #
        # @example HTML Attributes
        #   f.email_field("user.email", class: "form-control")
        #   => <input type="email" name="user[email]" id="user-email" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def email_field(name, **attributes)
          input(**_attributes(:email, name, attributes))
        end

        # Returns a URL input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.url_field("user.website")
        #   => <input type="url" name="user[website]" id="user-website" value="">
        #
        # @example HTML Attributes
        #   f.url_field("user.website", class: "form-control")
        #   => <input type="url" name="user[website]" id="user-website" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def url_field(name, **attributes)
          attributes[:value] = sanitize_url(attributes.fetch(:value) { _value(name) })

          input(**_attributes(:url, name, attributes))
        end

        # Returns a telephone input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example
        #   f.tel_field("user.telephone")
        #   => <input type="tel" name="user[telephone]" id="user-telephone" value="">
        #
        # @example HTML Attributes
        #   f.tel_field("user.telephone", class: "form-control")
        #   => <input type="tel" name="user[telephone]" id="user-telephone" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def tel_field(name, **attributes)
          input(**_attributes(:tel, name, attributes))
        end

        # Returns a hidden input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example
        #   f.hidden_field("delivery.customer_id")
        #   => <input type="hidden" name="delivery[customer_id]" id="delivery-customer-id" value="">
        #
        # @api public
        # @since 2.1.0
        def hidden_field(name, **attributes)
          input(**_attributes(:hidden, name, attributes))
        end

        # Returns a file input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        # @option attributes [String, Array] :accept Optional set of accepted MIME Types
        # @option attributes [Boolean] :multiple allow multiple file upload
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.file_field("user.avatar")
        #   => <input type="file" name="user[avatar]" id="user-avatar">
        #
        # @example HTML Attributes
        #   f.file_field("user.avatar", class: "avatar-upload")
        #   => <input type="file" name="user[avatar]" id="user-avatar" class="avatar-upload">
        #
        # @example Accepted MIME Types
        #   f.file_field("user.resume", accept: "application/pdf,application/ms-word")
        #   => <input type="file" name="user[resume]" id="user-resume" accept="application/pdf,application/ms-word">
        #
        #   f.file_field("user.resume", accept: ["application/pdf", "application/ms-word"])
        #   => <input type="file" name="user[resume]" id="user-resume" accept="application/pdf,application/ms-word">
        #
        # @example Accept multiple file uploads
        #   f.file_field("user.resume", multiple: true)
        #   => <input type="file" name="user[resume]" id="user-resume" multiple="multiple">
        #
        # @api public
        # @since 2.1.0
        def file_field(name, **attributes)
          form_attributes[:enctype] = "multipart/form-data"

          attributes[:accept] = Array(attributes[:accept]).join(ACCEPT_SEPARATOR) if attributes.key?(:accept)
          attributes = {type: :file, name: _input_name(name), id: _input_id(name), **attributes}

          input(**attributes)
        end

        # Returns a number input tag.
        #
        # For this tag, you can make use of the `max`, `min`, and `step` HTML attributes.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.number_field("book.percent_read")
        #   => <input type="number" name="book[percent_read]" id="book-percent-read" value="">
        #
        # @example Advanced attributes
        #   f.number_field("book.percent_read", min: 1, max: 100, step: 1)
        #   => <input type="number" name="book[percent_read]" id="book-precent-read" value="" min="1" max="100" step="1">
        #
        # @api public
        # @since 2.1.0
        def number_field(name, **attributes)
          input(**_attributes(:number, name, attributes))
        end

        # Returns a range input tag.
        #
        # For this tag, you can make use of the `max`, `min`, and `step` HTML attributes.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.range_field("book.discount_percentage")
        #   => <input type="range" name="book[discount_percentage]" id="book-discount-percentage" value="">
        #
        # @example Advanced attributes
        #   f.range_field("book.discount_percentage", min: 1, max: 1'0, step: 1)
        #   => <input type="number" name="book[discount_percentage]" id="book-discount-percentage" value="" min="1" max="100" step="1">
        #
        # @api public
        # @since 2.1.0
        def range_field(name, **attributes)
          input(**_attributes(:range, name, attributes))
        end

        # Returns a textarea tag.
        #
        # @param name [String] the input name
        # @param content [String] the content of the textarea
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.text_area("user.hobby")
        #   => <textarea name="user[hobby]" id="user-hobby"></textarea>
        #
        #   f.text_area "user.hobby", "Football"
        #   =>
        #   <textarea name="user[hobby]" id="user-hobby">
        #   Football</textarea>
        #
        # @example HTML attributes
        #   f.text_area "user.hobby", class: "form-control"
        #   => <textarea name="user[hobby]" id="user-hobby" class="form-control"></textarea>
        #
        # @api public
        # @since 2.1.0
        def text_area(name, content = nil, **attributes)
          if content.respond_to?(:to_hash)
            attributes = content
            content = nil
          end

          attributes = {name: _input_name(name), id: _input_id(name), **attributes}
          tag.textarea(content || _value(name), **attributes)
        end

        # Returns a text input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.text_field("user.first_name")
        #   => <input type="text" name="user[first_name]" id="user-first-name" value="">
        #
        # @example HTML Attributes
        #   f.text_field("user.first_name", class: "form-control")
        #   => <input type="text" name="user[first_name]" id="user-first-name" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def text_field(name, **attributes)
          input(**_attributes(:text, name, attributes))
        end
        alias_method :input_text, :text_field

        # Returns a search input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.search_field("search.q")
        #   => <input type="search" name="search[q]" id="search-q" value="">
        #
        # @example HTML Attributes
        #   f.search_field("search.q", class: "form-control")
        #   => <input type="search" name="search[q]" id="search-q" value="" class="form-control">
        #
        # @api public
        # @since 2.1.0
        def search_field(name, **attributes)
          input(**_attributes(:search, name, attributes))
        end

        # Returns a radio input tag.
        #
        # When editing a resource, the form automatically assigns the `checked` HTML attribute for
        # the tag.
        #
        # @param name [String] the input name
        # @param value [String] the input value
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.radio_button("book.category", "Fiction")
        #   f.radio_button("book.category", "Non-Fiction")
        #
        #   =>
        #   <input type="radio" name="book[category]" value="Fiction">
        #   <input type="radio" name="book[category]" value="Non-Fiction">
        #
        # @example HTML Attributes
        #   f.radio_button("book.category", "Fiction", class: "form-check")
        #   f.radio_button("book.category", "Non-Fiction", class: "form-check")
        #
        #   =>
        #   <input type="radio" name="book[category]" value="Fiction" class="form-check">
        #   <input type="radio" name="book[category]" value="Non-Fiction" class="form-check">
        #
        # @example Automatic checked value
        #   # Given the request params:
        #   # {book: {category: "Non-Fiction"}}
        #   f.radio_button("book.category", "Fiction")
        #   f.radio_button("book.category", "Non-Fiction")
        #
        #   =>
        #   <input type="radio" name="book[category]" value="Fiction">
        #   <input type="radio" name="book[category]" value="Non-Fiction" checked="checked">
        #
        # @api public
        # @since 2.1.0
        def radio_button(name, value, **attributes)
          attributes = {type: :radio, name: _input_name(name), value: value, **attributes}
          attributes[:checked] = true if _value(name).to_s == value.to_s

          input(**attributes)
        end

        # Returns a password input tag.
        #
        # @param name [String] the input name
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.password_field("signup.password")
        #   => <input type="password" name="signup[password]" id="signup-password" value="">
        #
        # @api public
        # @since 2.1.0
        def password_field(name, **attributes)
          attrs = {type: :password, name: _input_name(name), id: _input_id(name), value: nil, **attributes}
          attrs[:value] = EMPTY_STRING if attrs[:value].nil?

          input(**attrs)
        end

        # Returns a select input tag containing option tags for the given values.
        #
        # The values should be an enumerable of pairs of content (the displayed text for the option)
        # and value (the value for the option) strings.
        #
        # When editing a resource, automatically assigns the `selected` HTML attribute for any
        # option tags matching the resource's values.
        #
        # @param name [String] the input name
        # @param values [Hash] a Hash to generate `<option>` tags.
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values)
        #
        #   =>
        #   <select name="book[store]" id="book-store">
        #     <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example HTML Attributes
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values, class: "form-control")
        #
        #   =>
        #   <select name="book[store]" id="book-store" class="form-control">
        #     <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Selected options
        #   # Given the following request params:
        #   # {book: {store: "it"}}
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values)
        #
        #   =>
        #   <select name="book[store]" id="book-store">
        #     <option value="it" selected="selected">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Prompt option
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values, options: {prompt: "Select a store"})
        #
        #   =>
        #   <select name="book[store]" id="book-store">
        #     <option>Select a store</option>
        #     <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Selected option
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values, options: {selected: "it"})
        #
        #   =>
        #   <select name="book[store]" id="book-store">
        #     <option value="it" selected="selected">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Prompt option and HTML attributes
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.store", values, options: {prompt: "Select a store"}, class: "form-control")
        #
        #   =>
        #   <select name="book[store]" id="book-store" class="form-control">
        #     <option disabled="disabled">Select a store</option>
        #     <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Multiple select
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.stores", values, multiple: true)
        #
        #   =>
        #   <select name="book[store][]" id="book-store" multiple="multiple">
        #    <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Multiple select and HTML attributes
        #   values = {"Italy" => "it", "Australia" => "au"}
        #   f.select("book.stores", values, multiple: true, class: "form-control")
        #
        #   =>
        #   <select name="book[store][]" id="book-store" multiple="multiple" class="form-control">
        #     <option value="it">Italy</option>
        #     <option value="au">Australia</option>
        #   </select>
        #
        # @example Values as an array, supporting repeated entries
        #   values = [["Italy", "it"],
        #             ["---", ""],
        #             ["Afghanistan", "af"],
        #             ...
        #             ["Italy", "it"],
        #             ...
        #             ["Zimbabwe", "zw"]]
        #   f.select("book.stores", values)
        #
        #   =>
        #   <select name="book[store]" id="book-store">
        #     <option value="it">Italy</option>
        #     <option value="">---</option>
        #     <option value="af">Afghanistan</option>
        #     ...
        #     <option value="it">Italy</option>
        #     ...
        #     <option value="zw">Zimbabwe</option>
        #   </select>
        #
        # @api public
        # @since 2.1.0
        def select(name, values, **attributes) # rubocop:disable Metrics/AbcSize
          options = attributes.delete(:options) { {} }
          multiple = attributes[:multiple]
          attributes = {name: _select_input_name(name, multiple), id: _input_id(name), **attributes}
          prompt = options.delete(:prompt)
          selected = options.delete(:selected)
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

        # Returns a datalist input tag.
        #
        # @param name [String] the input name
        # @param values [Array,Hash] a collection that is transformed into `<option>` tags
        # @param list [String] the name of list for the text input; also the id of datalist
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic Usage
        #   values = ["Italy", "Australia"]
        #   f.datalist("book.stores", values, "books")
        #
        #   =>
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy"></option>
        #     <option value="Australia"></option>
        #   </datalist>
        #
        # @example Options As Hash
        #   values = Hash["Italy" => "it", "Australia" => "au"]
        #   f.datalist("book.stores", values, "books")
        #
        #   =>
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy">it</option>
        #     <option value="Australia">au</option>
        #   </datalist>
        #
        # @example Specifying custom attributes for the datalist input
        #   values = ["Italy", "Australia"]
        #   f.datalist "book.stores", values, "books", datalist: {class: "form-control"}
        #
        #   =>
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books" class="form-control">
        #     <option value="Italy"></option>
        #     <option value="Australia"></option>
        #   </datalist>
        #
        # @example Specifying custom attributes for the options list
        #   values = ["Italy", "Australia"]
        #   f.datalist("book.stores", values, "books", options: {class: "form-control"})
        #
        #   =>
        #   <input type="text" name="book[store]" id="book-store" value="" list="books">
        #   <datalist id="books">
        #     <option value="Italy" class="form-control"></option>
        #     <option value="Australia" class="form-control"></option>
        #   </datalist>
        #
        # @api public
        # @since 2.1.0
        def datalist(name, values, list, **attributes)
          options = attributes.delete(:options) || {}
          datalist = attributes.delete(:datalist) || {}

          attributes[:list] = list
          datalist[:id] = list

          (+"").tap { |output|
            output << text_field(name, **attributes)
            output << tag.datalist(**datalist) {
              (+"").tap { |inner|
                values.each do |value, content|
                  inner << tag.option(content, value: value, **options)
                end
              }.html_safe
            }
          }.html_safe
        end

        # Returns a button tag.
        #
        # @return [String] the tag
        #
        # @overload button(content, **attributes)
        #   Returns a button tag with the given content.
        #
        #   @param content [String] the content for the tag
        #   @param attributes [Hash] the tag's HTML attributes
        #
        # @overload button(**attributes, &block)
        #   Returns a button tag with the return value of the given block as the tag's content.
        #
        #   @param attributes [Hash] the tag's HTML attributes
        #   @yieldreturn [String] the tag content
        #
        # @example Basic usage
        #   f.button("Click me")
        #   => <button>Click me</button>
        #
        # @example HTML Attributes
        #   f.button("Click me", class: "btn btn-secondary")
        #   => <button class="btn btn-secondary">Click me</button>
        #
        # @example Returning content from a block
        #   <%= f.button class: "btn btn-secondary" do %>
        #     <span class="oi oi-check">
        #   <% end %>
        #
        #   =>
        #   <button class="btn btn-secondary">
        #     <span class="oi oi-check"></span>
        #   </button>
        #
        # @api public
        # @since 2.1.0
        def button(...)
          tag.button(...)
        end

        # Returns an image input tag, to be used as a visual button for the form.
        #
        # For security reasons, you should use the absolute URL of the given image.
        #
        # @param source [String] The absolute URL of the image
        # @param attributes [Hash] the tag's HTML attributes
        #
        # @return [String] the tag
        #
        # @example Basic usage
        #   f.image_button("https://hanamirb.org/assets/button.png")
        #   => <input type="image" src="https://hanamirb.org/assets/button.png">
        #
        # @example HTML Attributes
        #   f.image_button("https://hanamirb.org/assets/button.png", name: "image", width: "50")
        #   => <input name="image" width="50" type="image" src="https://hanamirb.org/assets/button.png">
        #
        # @api public
        # @since 2.1.0
        def image_button(source, **attributes)
          attributes[:type] = :image
          attributes[:src] = sanitize_url(source)

          input(**attributes)
        end

        # Returns a submit button tag.
        #
        # @return [String] the tag
        #
        # @overload submit(content, **attributes)
        #   Returns a submit button tag with the given content.
        #
        #   @param content [String] the content for the tag
        #   @param attributes [Hash] the tag's HTML attributes
        #
        # @overload submit(**attributes, &blk)
        #   Returns a submit button tag with the return value of the given block as the tag's
        #   content.
        #
        #   @param attributes [Hash] the tag's HTML attributes
        #   @yieldreturn [String] the tag content
        #
        # @example Basic usage
        #   f.submit("Create")
        #   => <button type="submit">Create</button>
        #
        # @example HTML Attributes
        #   f.submit("Create", class: "btn btn-primary")
        #   => <button type="submit" class="btn btn-primary">Create</button>
        #
        # @example Returning content from a block
        #   <%= f.submit(class: "btn btn-primary") do %>
        #     <span class="oi oi-check">
        #   <% end %>
        #
        #   =>
        #   <button type="submit" class="btn btn-primary">
        #     <span class="oi oi-check"></span>
        #   </button>
        #
        # @api public
        # @since 2.1.0
        def submit(content = nil, **attributes, &blk)
          if content.is_a?(::Hash)
            attributes = content
            content = nil
          end

          attributes = {type: :submit, **attributes}
          tag.button(content, **attributes, &blk)
        end

        # Returns an input tag.
        #
        # Generates an input tag without any special handling. For more convenience and other
        # advanced features, see the other methods of the form builder.
        #
        # @param attributes [Hash] the tag's HTML attributes
        # @yieldreturn [String] the tag content
        #
        # @return [String] the tag
        #
        # @since 2.1.0
        # @api public
        #
        # @example Basic usage
        #   f.input(type: :text, name: "book[title]", id: "book-title", value: book.title)
        #   => <input type="text" name="book[title]" id="book-title" value="Hanami book">
        #
        # @api public
        # @since 2.1.0
        def input(...)
          tag.input(...)
        end

        private

        # @api private
        # @since 2.1.0
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
        # @since 2.1.0
        def _csrf_token(values, attributes)
          return [] if values.csrf_token.nil?

          return [] if EXCLUDED_CSRF_METHODS.include?(attributes[:method])

          [true, values.csrf_token]
        end

        # @api private
        # @since 2.1.0
        def _attributes(type, name, attributes)
          attrs = {
            type: type,
            name: _input_name(name),
            id: _input_id(name),
            value: _value(name)
          }
          attrs.merge!(attributes)
          attrs[:value] = escape_html(attrs[:value]).html_safe
          attrs
        end

        # @api private
        # @since 2.1.0
        def _input_name(name)
          tokens = _split_input_name(name)
          result = tokens.shift

          tokens.each do |t|
            if t =~ %r{\A\d+\z}
              result << "[]"
            else
              result << "[#{t}]"
            end
          end

          result
        end

        # @api private
        # @since 2.1.0
        def _input_id(name)
          [base_name, name].compact.join(INPUT_NAME_SEPARATOR).to_s.tr("._", "-")
        end

        # @api private
        # @since 2.1.0
        def _value(name)
          values.get(*_split_input_name(name).map(&:to_sym))
        end

        # @api private
        # @since 2.1.0
        def _split_input_name(name)
          [
            *base_name.to_s.split(INPUT_NAME_SEPARATOR),
            *name.to_s.split(INPUT_NAME_SEPARATOR)
          ].compact
        end

        # @api private
        # @since 2.1.0
        #
        # @see #check_box
        def _hidden_field_for_check_box(name, attributes)
          return unless attributes[:value].nil? || !attributes[:unchecked_value].nil?

          input(
            type: :hidden,
            name: attributes[:name] || _input_name(name),
            value: (attributes.delete(:unchecked_value) || DEFAULT_UNCHECKED_VALUE).to_s
          )
        end

        # @api private
        # @since 2.1.0
        #
        # @see #check_box
        def _attributes_for_check_box(name, attributes)
          attributes = {
            type: :checkbox,
            name: _input_name(name),
            id: _input_id(name),
            value: (attributes.delete(:checked_value) || DEFAULT_CHECKED_VALUE).to_s,
            **attributes
          }

          attributes[:checked] = true if _check_box_checked?(attributes[:value], _value(name))

          attributes
        end

        # @api private
        # @since 1.2.0
        def _select_input_name(name, multiple)
          select_name = _input_name(name)
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
              _is_current_value?(input_value, value) ||
              _is_in_selected_values?(multiple, selected, value) ||
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
