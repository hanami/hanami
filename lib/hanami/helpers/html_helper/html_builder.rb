# frozen_string_literal: true

require "dry/core/basic_object"
require "escape_utils"

# Ported from Hanami 1.x & adapted from `papercraft` gem implementation:
#
# Papercraft is Copyright (c) digital-fabric
# Released under the MIT License
module Hanami
  module Helpers
    module HTMLHelper
      # HTML Builder
      #
      # @since 0.1.0
      class HTMLBuilder < Dry::Core::BasicObject
        # HTML5 empty tags
        #
        # @since 0.1.0
        # @api private
        #
        # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element
        EMPTY_TAGS = {
          area: true,
          base: true,
          br: true,
          col: true,
          embed: true,
          hr: true,
          img: true,
          input: true,
          keygen: true,
          link: true,
          menuitem: true,
          meta: true,
          param: true,
          source: true,
          track: true,
          wbr: true
        }.freeze

        # New line separator
        #
        # @since 0.1.0
        # @api private
        NEWLINE = "\n"

        # @since 2.0.0
        # @api private
        S_LT              = "<"

        # @since 2.0.0
        # @api private
        S_GT              = ">"

        # @since 2.0.0
        # @api private
        S_LT_SLASH        = "</"

        # @since 2.0.0
        # @api private
        S_SPACE_LT_SLASH  = " </"

        # @since 2.0.0
        # @api private
        S_SLASH_GT        = "/>"

        # @since 2.0.0
        # @api private
        S_SPACE           = " "

        # @since 2.0.0
        # @api private
        S_EQUAL_QUOTE     = '="'

        # @since 2.0.0
        # @api private
        S_QUOTE           = '"'

        # @since 2.0.0
        # @api private
        S_UNDERSCORE      = "_"

        # @since 2.0.0
        # @api private
        S_DASH            = "-"

        # @since 2.0.0
        # @api private
        S_TAG_METHOD_LINE = __LINE__ + 2

        # @since 2.0.0
        # @api private
        S_CONTENT_TAG_METHOD = <<~RUBY
          # @since 2.0.0
          # @api private
          S_TAG_%<TAG>s_PRE = %<tag_pre>s

          # @since 2.0.0
          # @api private
          S_TAG_%<TAG>s_CLOSE = %<tag_close>s

          # `%<tag>s` HTML tag
          #
          # @params type [Symbol,String,#to_s] HTML tag type
          # @params content [String,NilClass] optional content
          # @params attributes [Hash] HTML attributes
          # @params blk [Proc] optional nested contents
          #
          # @return void
          #
          # @see #tag
          #
          # @since 0.1.0
          # @api public
          #
          # @example
          #   html.%<tag>s
          #     # => <%<tag>s></%<tag>s>
          #
          #   html.%<tag>s(id: "foo")
          #     # => <%<tag>s id="foo"></%<tag>s>
          #
          #   html.%<tag>s(id: "foo", class: "full-width")
          #     # => <%<tag>s id="foo" class="full-width"></%<tag>s>
          #
          #   html.%<tag>s(class: ["foo", "bar"])
          #     # => <%<tag>s class="foo bar"></%<tag>s>
          #
          #   html.%<tag>s(required: false)
          #     # => <%<tag>s></%<tag>s>
          #
          #   html.%<tag>s(required: true)
          #     # => <%<tag>s required></%<tag>s>
          #
          #   html.%<tag>s("Hello")
          #     # => <%<tag>s>Hello</%<tag>s>
          #
          #   html.%<tag>s("Hello", id: "foo", class: "full-width")
          #     # => <%<tag>s id="foo" class="full-width">Hello</%<tag>s>
          #
          #   html.%<tag>s("Hello ") do
          #     span "World"
          #   end
          #     # => <%<tag>s>Hello <span>World<span></%<tag>s>
          def %<tag>s(content = nil, **attributes, &blk)
            if content.is_a?(::Hash) && attributes.empty?
              attributes = content
              content = nil
            end

            @buffer << S_TAG_%<TAG>s_PRE
            emit_attributes(attributes)
            if blk
              @buffer << S_GT
              instance_eval(&blk)
              @buffer << S_TAG_%<TAG>s_CLOSE
            elsif content
              @buffer << S_GT << escape_content(content.to_s) << S_TAG_%<TAG>s_CLOSE
            else
              @buffer << S_GT << S_TAG_%<TAG>s_CLOSE
            end

            @buffer.html_safe
          end
        RUBY

        # @since 2.0.0
        # @api private
        S_EMPTY_TAG_METHOD = <<~RUBY
          # @since 2.0.0
          # @api private
          S_TAG_%<TAG>s_PRE = %<tag_pre>s

          # `%<tag>s` HTML empty tag
          #
          # @params attributes [Hash] HTML attributes
          #
          # @return void
          #
          # @since 2.0.0
          # @api public
          #
          # @see #empty_tag
          #
          # @example
          #   html.%<tag>s
          #     # => <%<tag>s>
          #
          #   html.%<tag>s(id: "foo")
          #     # => <%<tag>s id="foo">
          #
          #   html.%<tag>s(id: "foo", class: "full-width")
          #     # => <%<tag>s id="foo" class="full-width">
          #
          #   html.%<tag>s(class: ["foo", "bar"])
          #     # => <%<tag>s class="foo bar">
          #
          #   html.%<tag>s(required: false)
          #     # => <%<tag>s>
          #
          #   html.%<tag>s(required: true)
          #     # => <%<tag>s required>
          def %<tag>s(**attributes)
            @buffer << S_TAG_%<TAG>s_PRE
            emit_attributes(attributes)
            @buffer << S_GT
          end
        RUBY

        def initialize(&blk)
          super()
          @buffer = +""
          instance_eval(&blk) if blk
        end

        # Generate HTML content tag
        #
        # @params type [Symbol,String,#to_s] HTML tag type
        # @params content [String,NilClass] optional content
        # @params attributes [Hash] HTML attributes
        # @params blk [Proc] optional nested contents
        #
        # @return void
        #
        # @since 0.1.0
        # @api public
        #
        # @example
        #   html.tag(:my_tag)
        #     # => <my-tag></my-tag>
        #
        #   html.tag(:my_tag, id: "foo")
        #     # => <my-tag id="foo"></my-tag>
        #
        #   html.tag(:my_tag, id: "foo", class: "full-width")
        #     # => <my-tag id="foo" class="full-width"></my-tag>
        #
        #   html.tag(:my_tag, class: ["foo", "bar"])
        #     # => <my-tag class="foo bar"></my-tag>
        #
        #   html.tag(:my_tag, required: false)
        #     # => <my-tag></my-tag>
        #
        #   html.tag(:my_tag, required: true)
        #     # => <my-tag required></my-tag>
        #
        #   html.tag(:my_tag, "Hello")
        #     # => <my-tag>Hello</my-tag>
        #
        #   html.tag(:my_tag, "Hello", id: "foo", class: "full-width")
        #     # => <my-tag id="foo" class="full-width">Hello</my-tag>
        #
        #   html.tag(:my_tag, "Hello ") do
        #     span "World"
        #   end
        #     # => <my-tag>Hello <span>World<span></my-tag>
        def tag(type, content = nil, **attributes, &blk)
          type = tag_name(type.to_s)

          if content.is_a?(::Hash) && attributes.empty?
            attributes = content
            content = nil
          end
          @buffer << S_LT << type
          emit_attributes(attributes)
          if blk
            @buffer << S_GT
            instance_eval(&blk)
            @buffer << S_LT_SLASH << type << S_GT
          elsif content
            @buffer << S_GT << escape_content(content.to_s) <<
              S_LT_SLASH << type << S_GT
          else
            @buffer << S_GT <<
              S_LT_SLASH << type << S_GT
          end
        end

        # Generate HTML empty tag
        #
        # @params type [Symbol,String,#to_s] HTML tag type
        # @params attributes [Hash] HTML attributes
        #
        # @return void
        #
        # @since 0.1.0
        # @api public
        #
        # @example
        #   html.empty_tag(:my_tag)
        #     # => <my-tag>
        #
        #   html.empty_tag(:my_tag, id: "foo")
        #     # => <my-tag id="foo">
        #
        #   html.empty_tag(:my_tag, id: "foo", class: "full-width")
        #     # => <my-tag id="foo" class="full-width">
        #
        #   html.empty_tag(:my_tag, class: ["foo", "bar"])
        #     # => <my-tag class="foo bar">
        #
        #   html.empty_tag(:my_tag, required: false)
        #     # => <my-tag>
        #
        #   html.empty_tag(:my_tag, required: true)
        #     # => <my-tag required>
        def empty_tag(type, **attributes)
          @buffer << S_LT << tag_name(type.to_s)
          emit_attributes(attributes)
          @buffer << S_GT
        end

        # Define a HTML fragment
        #
        # @param blk [Proc] the optional nested content espressed as a block
        #
        # @return void
        #
        # @since 0.2.6
        # @api public
        #
        # @example
        #   html.fragment("Hanami") # => Hanami
        #
        #   html do
        #     p "hello"
        #     p "hanami"
        #   end
        #   # =>
        #     <p>hello</p>
        #     <p>hanami</p>
        def fragment(&blk)
          instance_eval(&blk)
        end

        # Defines a plain string of text. This particularly useful when you
        # want to build complex HTML.
        #
        # @param content [String] the text to be rendered.
        #
        # @return void
        #
        # @since 0.2.5
        # @api public
        #
        # @example
        #
        #   <%=
        #     html.label do
        #       text "Option 1"
        #       radio_button :option, 1
        #     end
        #   %>
        #
        #   <!-- output -->
        #   <label>
        #     Option 1
        #     <input type="radio" name="option" value="1" />
        #   </label>
        def text(content)
          @buffer << escape_content(content).to_s
        end

        # Concat self with another builder
        #
        # @param other [Hanami::Helpers::HtmlHelper::HtmlBuilder] the other builder
        #
        # @retun void
        #
        # @since 2.0.0
        # @api public
        #
        # @example Anonymous concat
        #
        #   html.div("Hello") + html.div("Hanami")
        #     # => "<div>Hello</div><div>Hanami</div>"
        #
        # @example Assign and concat
        #
        #   hello  = html { div "Hello" }
        #   hanami = html { div "Hanami" }
        #
        #   hello + hanami
        #     # => "<div>Hello</div><div>Hanami</div>"
        def +(other)
          to_s + other.to_s
        end

        # Return HTML
        #
        # @return [String] the output HTML
        #
        # @since 0.1.0
        # @api public
        def to_s
          @buffer.html_safe
        end

        # Clear internal buffer
        #
        # @return [void]
        #
        # @since 2.0.0
        # @api private
        def clear
          @buffer = @buffer.class.new
        end

        # Generates tag metods on the fly
        #
        # @since 0.1.0
        # @api private
        def method_missing(method_name, *args, **kwargs, &blk)
          tag = method_name.to_s
          type = tag_name(tag)
          code = (EMPTY_TAGS.key?(method_name) ? S_EMPTY_TAG_METHOD : S_CONTENT_TAG_METHOD) % {
            tag: tag,
            TAG: tag.upcase,
            tag_pre: "<#{type}".inspect,
            tag_close: "</#{type}>".inspect
          }

          self.class.class_eval(code, __FILE__, S_TAG_METHOD_LINE)

          __send__(method_name, *args, **kwargs, &blk)
        end

        # @since 1.2.2
        # @api private
        def respond_to_missing?(*)
          true
        end

        private

        # @since 2.0.0
        # @api private
        def tag_name(tag)
          tag.tr(S_UNDERSCORE, S_DASH)
        end

        # @since 2.0.0
        # @api private
        alias_method :attribute_name, :tag_name

        # @since 2.0.0
        # @api private
        def escape_content(content)
          ::Hanami::View::HTML.escape_html(content)
        end

        def escape_uri(uri)
          ::EscapeUtils.escape_uri(string)
        end

        # @since 2.0.0
        # @api private
        def emit_attributes(attributes) # rubocop:disable Metrics/AbcSize
          return if attributes.empty?

          attributes.each do |name, value|
            case name
            when :src, :href
              @buffer << S_SPACE << name.to_s << S_EQUAL_QUOTE <<
                escape_uri(value) << S_QUOTE
            else
              case value
              when true
                @buffer << S_SPACE << attribute_name(name.to_s)
              when false, nil
                # emit nothing
              when Array
                @buffer << S_SPACE << name.to_s << S_EQUAL_QUOTE <<
                  value.join(S_SPACE) << S_QUOTE
              else
                @buffer << S_SPACE << attribute_name(name.to_s) <<
                  S_EQUAL_QUOTE << value.to_s << S_QUOTE
              end
            end
          end
        end
      end
    end
  end
end
