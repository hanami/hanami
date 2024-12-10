# frozen_string_literal: true

require "hanami/cyg_utils/inflector"
require "transproc"
require "concurrent/map"

module Hanami
  module CygUtils
    # String on steroids
    #
    # @since 0.1.0
    class String
      # Empty string for #classify
      #
      # @since 0.6.0
      # @api private
      EMPTY_STRING        = ""

      # Separator between Ruby namespaces
      #
      # @since 0.1.0
      # @api private
      NAMESPACE_SEPARATOR = "::"

      # Separator for #classify
      #
      # @since 0.3.0
      # @api private
      CLASSIFY_SEPARATOR  = "_"

      # Regexp for #tokenize
      #
      # @since 0.3.0
      # @api private
      TOKENIZE_REGEXP     = /\((.*)\)/.freeze

      # Separator for #tokenize
      #
      # @since 0.3.0
      # @api private
      TOKENIZE_SEPARATOR  = "|"

      # Separator for #underscore
      #
      # @since 0.3.0
      # @api private
      UNDERSCORE_SEPARATOR = "/"

      # gsub second parameter used in #underscore
      #
      # @since 0.3.0
      # @api private
      UNDERSCORE_DIVISION_TARGET = '\1_\2'

      # Separator for #titleize
      #
      # @since 0.4.0
      # @api private
      TITLEIZE_SEPARATOR = " "

      # Separator for #capitalize
      #
      # @since 0.5.2
      # @api private
      CAPITALIZE_SEPARATOR = " "

      # Separator for #dasherize
      #
      # @since 0.4.0
      # @api private
      DASHERIZE_SEPARATOR = "-"

      # Regexp for #classify
      #
      # @since 0.3.4
      # @api private
      CLASSIFY_WORD_SEPARATOR = /#{CLASSIFY_SEPARATOR}|#{NAMESPACE_SEPARATOR}|#{UNDERSCORE_SEPARATOR}|#{DASHERIZE_SEPARATOR}/.freeze # rubocop:disable Layout/LineLength

      @__transformations__ = Concurrent::Map.new

      extend Transproc::Registry
      extend Transproc::Composer

      # Applies the given transformation(s) to `input`
      #
      # It performs a pipeline of transformations, by applying the given
      # functions from `Hanami::CygUtils::String` and `::String`.
      # The transformations are applied in the given order.
      #
      # It doesn't mutate the input, unless you use destructive methods from `::String`
      #
      # @param input [::String] the string to be transformed
      # @param transformations [Array<Symbol,Proc,Array>] one or many
      #   transformations expressed as:
      #     * `Symbol` to reference a function from `Hanami::CygUtils::String` or `String`.
      #     * `Proc` an anonymous function that MUST accept one input
      #     * `Array` where the first element is a `Symbol` to reference a
      #       function from `Hanami::CygUtils::String` or `String` and the rest of
      #       the elements are the arguments to pass
      #
      # @return [::String] the result of the transformations
      #
      # @raise [NoMethodError] if a `Hanami::CygUtils::String` and `::String`
      #   don't respond to a given method name
      #
      # @raise [ArgumentError] if a Proc transformation has an arity not equal
      #   to 1
      #
      # @since 1.1.0
      #
      # @example Basic usage
      #   require "hanami/cyg_utils/string"
      #
      #   Hanami::CygUtils::String.transform("hanami/utils", :underscore, :classify)
      #     # => "Hanami::Utils"
      #
      #   Hanami::CygUtils::String.transform("Hanami::CygUtils::String", [:gsub, /[aeiouy]/, "*"], :demodulize)
      #     # => "H*n*m*"
      #
      #   Hanami::CygUtils::String.transform("Hanami", ->(s) { s.upcase })
      #     # => "HANAMI"
      #
      # @example Unkown transformation
      #   require "hanami/cyg_utils/string"
      #
      #   Hanami::CygUtils::String.transform("Sakura", :foo)
      #     # => NoMethodError: undefined method `:foo' for "Sakura":String
      #
      # @example Proc with arity not equal to 1
      #   require "hanami/cyg_utils/string"
      #
      #   Hanami::CygUtils::String.transform("Cherry", -> { "blossom" }))
      #     # => ArgumentError: wrong number of arguments (given 1, expected 0)
      #
      def self.transform(input, *transformations)
        fn = @__transformations__.fetch_or_store(transformations.hash) do
          compose do |fns|
            transformations.each do |transformation, *args|
              fns << if transformation.is_a?(Proc)
                       transformation
                     elsif contain?(transformation)
                       self[transformation, *args]
                     elsif input.respond_to?(transformation)
                       t(:bind, input, ->(i) { i.public_send(transformation, *args) })
                     else
                       raise NoMethodError.new(%(undefined method `#{transformation.inspect}' for #{input.inspect}:#{input.class})) # rubocop:disable Layout/LineLength
                     end
            end
          end
        end

        fn.call(input)
      end

      # Extracted from `transproc` source code
      #
      # `transproc` is Copyright 2014 by Piotr Solnica (piotr.solnica@gmail.com),
      # released under the MIT License
      #
      # @since 1.1.0
      # @api private
      def self.bind(value, binding, fun)
        binding.instance_exec(value, &fun)
      end

      # Returns a titleized version of the string
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.titleize('hanami utils') # => "Hanami Utils"
      def self.titleize(input)
        string = ::String.new(input.to_s)
        underscore(string).split(CLASSIFY_SEPARATOR).map(&:capitalize).join(TITLEIZE_SEPARATOR)
      end

      # Returns a capitalized version of the string
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.capitalize('hanami') # => "Hanami"
      #
      #   Hanami::CygUtils::String.capitalize('hanami utils') # => "Hanami utils"
      #
      #   Hanami::CygUtils::String.capitalize('Hanami Utils') # => "Hanami utils"
      #
      #   Hanami::CygUtils::String.capitalize('hanami_utils') # => "Hanami utils"
      #
      #   Hanami::CygUtils::String.capitalize('hanami-utils') # => "Hanami utils"
      def self.capitalize(input)
        string = ::String.new(input.to_s)
        head, *tail = underscore(string).split(CLASSIFY_SEPARATOR)

        tail.unshift(head.capitalize).join(CAPITALIZE_SEPARATOR)
      end

      # Returns a CamelCase version of the string
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.classify('hanami_utils') # => 'HanamiUtils'
      def self.classify(input)
        string = ::String.new(input.to_s)
        words = underscore(string).split(CLASSIFY_WORD_SEPARATOR).map!(&:capitalize)
        delimiters = underscore(string).scan(CLASSIFY_WORD_SEPARATOR)

        delimiters.map! do |delimiter|
          delimiter == CLASSIFY_SEPARATOR ? EMPTY_STRING : NAMESPACE_SEPARATOR
        end

        words.zip(delimiters).join
      end

      # Returns a downcased and underscore separated version of the string
      #
      # Revised version of `ActiveSupport::Inflector.underscore` implementation
      # @see https://github.com/rails/rails/blob/feaa6e2048fe86bcf07e967d6e47b865e42e055b/activesupport/lib/active_support/inflector/methods.rb#L90
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.underscore('HanamiUtils') # => 'hanami_utils'
      def self.underscore(input)
        string = ::String.new(input.to_s)
        string.gsub!(NAMESPACE_SEPARATOR, UNDERSCORE_SEPARATOR)
        string.gsub!(NAMESPACE_SEPARATOR, UNDERSCORE_SEPARATOR)
        string.gsub!(/([A-Z\d]+)([A-Z][a-z])/, UNDERSCORE_DIVISION_TARGET)
        string.gsub!(/([a-z\d])([A-Z])/, UNDERSCORE_DIVISION_TARGET)
        string.gsub!(/[[:space:]]|\-|\./, UNDERSCORE_DIVISION_TARGET)
        string.downcase
      end

      # Returns a downcased and dash separated version of the string
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.dasherize('Hanami Utils') # => 'hanami-utils'

      #   Hanami::CygUtils::String.dasherize('hanami_utils') # => 'hanami-utils'
      #
      #   Hanami::CygUtils::String.dasherize('HanamiUtils') # => "hanami-utils"
      def self.dasherize(input)
        string = ::String.new(input.to_s)
        underscore(string).split(CLASSIFY_SEPARATOR).join(DASHERIZE_SEPARATOR)
      end

      # Returns the string without the Ruby namespace of the class
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.demodulize('Hanami::CygUtils::String') # => 'String'
      #
      #   Hanami::CygUtils::String.demodulize('String') # => 'String'
      def self.demodulize(input)
        ::String.new(input.to_s).split(NAMESPACE_SEPARATOR).last
      end

      # Returns the top level namespace name
      #
      # @param input [::String] the input
      #
      # @return [::String] the transformed string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.namespace('Hanami::CygUtils::String') # => 'Hanami'
      #
      #   Hanami::CygUtils::String.namespace('String') # => 'String'
      def self.namespace(input)
        ::String.new(input.to_s).split(NAMESPACE_SEPARATOR).first
      end

      # Returns a pluralized version of self.
      #
      # @param input [::String] the input
      #
      # @return [::String] the pluralized string.
      #
      # @since 1.1.0
      #
      # @see Hanami::CygUtils::Inflector
      # @deprecated
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.pluralize('book') # => 'books'
      def self.pluralize(input)
        string = ::String.new(input.to_s)
        Inflector.pluralize(string)
      end

      # Returns a singularized version of self.
      #
      # @param input [::String] the input
      #
      # @return [::String] the singularized string.
      #
      # @since 1.1.0
      # @deprecated
      #
      # @see Hanami::CygUtils::Inflector
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.singularize('books') # => 'book'
      def self.singularize(input)
        string = ::String.new(input.to_s)
        Inflector.singularize(string)
      end

      # Replaces the rightmost match of `pattern` with `replacement`
      #
      # If the pattern cannot be matched, it returns the original string.
      #
      # This method does NOT mutate the original string.
      #
      # @param input [::String] the input
      # @param pattern [Regexp, ::String] the pattern to find
      # @param replacement [String] the string to replace
      #
      # @return [::String] the replaced string
      #
      # @since 1.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   Hanami::CygUtils::String.rsub('authors/books/index', %r{/}, '#')
      #     # => 'authors/books#index'
      def self.rsub(input, pattern, replacement)
        string = ::String.new(input.to_s)
        if i = string.rindex(pattern)
          s = string.dup
          s[i] = replacement
          s
        else
          string
        end
      end

      # Initialize the string
      #
      # @param string [::String, Symbol] the value we want to initialize
      #
      # @return [Hanami::CygUtils::String] self
      #
      # @since 0.1.0
      # @deprecated
      def initialize(string)
        @string = string.to_s
      end

      # Returns a titleized version of the string
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.4.0
      # @deprecated Use {Hanami::CygUtils::String.titleize}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'hanami utils'
      #   string.titleize # => "Hanami Utils"
      def titleize
        self.class.new underscore.split(CLASSIFY_SEPARATOR).map(&:capitalize).join(TITLEIZE_SEPARATOR)
      end

      # Returns a capitalized version of the string
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.5.2
      # @deprecated Use {Hanami::CygUtils::String.capitalize}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'hanami'
      #   string.capitalize # => "Hanami"
      #
      #   string = Hanami::CygUtils::String.new 'hanami utils'
      #   string.capitalize # => "Hanami utils"
      #
      #   string = Hanami::CygUtils::String.new 'Hanami Utils'
      #   string.capitalize # => "Hanami utils"
      #
      #   string = Hanami::CygUtils::String.new 'hanami_utils'
      #   string.capitalize # => "Hanami utils"
      #
      #   string = Hanami::CygUtils::String.new 'hanami-utils'
      #   string.capitalize # => "Hanami utils"
      def capitalize
        head, *tail = underscore.split(CLASSIFY_SEPARATOR)

        self.class.new(
          tail.unshift(head.capitalize).join(CAPITALIZE_SEPARATOR)
        )
      end

      # Returns a CamelCase version of the string
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.1.0
      # @deprecated Use {Hanami::CygUtils::String.classify}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'hanami_utils'
      #   string.classify # => 'HanamiUtils'
      def classify
        words = underscore.split(CLASSIFY_WORD_SEPARATOR).map!(&:capitalize)
        delimiters = underscore.scan(CLASSIFY_WORD_SEPARATOR)

        delimiters.map! do |delimiter|
          delimiter == CLASSIFY_SEPARATOR ? EMPTY_STRING : NAMESPACE_SEPARATOR
        end

        self.class.new words.zip(delimiters).join
      end

      # Returns a downcased and underscore separated version of the string
      #
      # Revised version of `ActiveSupport::Inflector.underscore` implementation
      # @see https://github.com/rails/rails/blob/feaa6e2048fe86bcf07e967d6e47b865e42e055b/activesupport/lib/active_support/inflector/methods.rb#L90
      #
      # @return [Hanami::CygUtils::String] the transformed string
      # @deprecated Use {Hanami::CygUtils::String.underscore}
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'HanamiUtils'
      #   string.underscore # => 'hanami_utils'
      def underscore
        new_string = gsub(NAMESPACE_SEPARATOR, UNDERSCORE_SEPARATOR)
        new_string.gsub!(/([A-Z\d]+)([A-Z][a-z])/, UNDERSCORE_DIVISION_TARGET)
        new_string.gsub!(/([a-z\d])([A-Z])/, UNDERSCORE_DIVISION_TARGET)
        new_string.gsub!(/[[:space:]]|\-|\./, UNDERSCORE_DIVISION_TARGET)
        new_string.downcase!
        self.class.new new_string
      end

      # Returns a downcased and dash separated version of the string
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.4.0
      # @deprecated Use {Hanami::CygUtils::String.dasherize}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'Hanami Utils'
      #   string.dasherize # => 'hanami-utils'
      #
      #   string = Hanami::CygUtils::String.new 'hanami_utils'
      #   string.dasherize # => 'hanami-utils'
      #
      #   string = Hanami::CygUtils::String.new 'HanamiUtils'
      #   string.dasherize # => "hanami-utils"
      def dasherize
        self.class.new underscore.split(CLASSIFY_SEPARATOR).join(DASHERIZE_SEPARATOR)
      end

      # Returns the string without the Ruby namespace of the class
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.1.0
      # @deprecated Use {Hanami::CygUtils::String.demodulize}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'Hanami::CygUtils::String'
      #   string.demodulize # => 'String'
      #
      #   string = Hanami::CygUtils::String.new 'String'
      #   string.demodulize # => 'String'
      def demodulize
        self.class.new split(NAMESPACE_SEPARATOR).last
      end

      # Returns the top level namespace name
      #
      # @return [Hanami::CygUtils::String] the transformed string
      #
      # @since 0.1.2
      # @deprecated Use {Hanami::CygUtils::String.namespace}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'Hanami::CygUtils::String'
      #   string.namespace # => 'Hanami'
      #
      #   string = Hanami::CygUtils::String.new 'String'
      #   string.namespace # => 'String'
      def namespace
        self.class.new split(NAMESPACE_SEPARATOR).first
      end

      # It iterates through the tokens and calls the given block.
      # A token is a substring wrapped by `()` and separated by `|`.
      #
      # @yield the block that is called for each token.
      #
      # @return [void]
      #
      # @since 0.1.0
      # @deprecated
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new 'Hanami::(Utils|App)'
      #   string.tokenize do |token|
      #     puts token
      #   end
      #
      #   # =>
      #     'Hanami::Utils'
      #     'Hanami::App'
      #
      def tokenize
        if match = TOKENIZE_REGEXP.match(@string)
          pre  = match.pre_match
          post = match.post_match
          tokens = match[1].split(TOKENIZE_SEPARATOR)
          tokens.each do |token|
            yield(self.class.new("#{pre}#{token}#{post}"))
          end
        else
          yield(self.class.new(@string))
        end

        nil
      end

      # Returns a pluralized version of self.
      #
      # @return [Hanami::CygUtils::String] the pluralized string.
      #
      # @api private
      # @since 0.4.1
      # @deprecated
      #
      # @see Hanami::CygUtils::Inflector
      def pluralize
        self.class.new Inflector.pluralize(self)
      end

      # Returns a singularized version of self.
      #
      # @return [Hanami::CygUtils::String] the singularized string.
      #
      # @api private
      # @since 0.4.1
      # @deprecated
      #
      # @see Hanami::CygUtils::Inflector
      def singularize
        self.class.new Inflector.singularize(self)
      end

      # Returns the hash of the internal string
      #
      # @return [Integer]
      #
      # @since 0.3.0
      # @deprecated
      def hash
        @string.hash
      end

      # Returns a string representation
      #
      # @return [::String]
      #
      # @since 0.3.0
      # @deprecated
      def to_s
        @string
      end

      alias_method :to_str, :to_s

      # Equality
      #
      # @return [TrueClass,FalseClass]
      #
      # @since 0.3.0
      # @deprecated
      def ==(other)
        to_s == other
      end

      alias_method :eql?, :==

      # Splits the string with the given pattern
      #
      # @return [Array<::String>]
      #
      # @see http://www.ruby-doc.org/core/String.html#method-i-split
      #
      # @since 0.3.0
      # @deprecated
      def split(pattern, limit = 0)
        @string.split(pattern, limit)
      end

      # Replaces the given pattern with the given replacement
      #
      # @return [::String]
      #
      # @see http://www.ruby-doc.org/core/String.html#method-i-gsub
      #
      # @since 0.3.0
      # @deprecated
      def gsub(pattern, replacement = nil, &blk)
        if block_given?
          @string.gsub(pattern, &blk)
        else
          @string.gsub(pattern, replacement)
        end
      end

      # Iterates through the string, matching the pattern.
      # Either return all those patterns, or pass them to the block.
      #
      # @return [Array<::String>]
      #
      # @see http://www.ruby-doc.org/core/String.html#method-i-scan
      #
      # @since 0.6.0
      # @deprecated
      def scan(pattern, &blk)
        @string.scan(pattern, &blk)
      end

      # Replaces the rightmost match of `pattern` with `replacement`
      #
      # If the pattern cannot be matched, it returns the original string.
      #
      # This method does NOT mutate the original string.
      #
      # @param pattern [Regexp, String] the pattern to find
      # @param replacement [String, Hanami::CygUtils::String] the string to replace
      #
      # @return [Hanami::CygUtils::String] the replaced string
      #
      # @since 0.6.0
      # @deprecated Use {Hanami::CygUtils::String.rsub}
      #
      # @example
      #   require 'hanami/cyg_utils/string'
      #
      #   string = Hanami::CygUtils::String.new('authors/books/index')
      #   result = string.rsub(/\//, '#')
      #
      #   puts string
      #     # => #<Hanami::CygUtils::String:0x007fdb41233ad8 @string="authors/books/index">
      #
      #   puts result
      #     # => #<Hanami::CygUtils::String:0x007fdb41232ed0 @string="authors/books#index">
      def rsub(pattern, replacement)
        if i = rindex(pattern)
          s    = @string.dup
          s[i] = replacement
          self.class.new s
        else
          self
        end
      end

      # Overrides Ruby's method_missing in order to provide ::String interface
      #
      # @api private
      # @since 0.3.0
      #
      # @raise [NoMethodError] If doesn't respond to the given method
      def method_missing(method_name, *args, &blk)
        unless respond_to?(method_name)
          raise NoMethodError.new(%(undefined method `#{method_name}' for "#{@string}":#{self.class}))
        end

        s = @string.__send__(method_name, *args, &blk)
        s = self.class.new(s) if s.is_a?(::String)
        s
      end

      # Overrides Ruby's respond_to_missing? in order to support ::String interface
      #
      # @api private
      # @since 0.3.0
      def respond_to_missing?(method_name, include_private = false)
        @string.respond_to?(method_name, include_private)
      end
    end
  end
end
