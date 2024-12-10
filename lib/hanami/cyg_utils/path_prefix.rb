# frozen_string_literal: true

require "hanami/cyg_utils/string"
require "hanami/cyg_utils/kernel"

module Hanami
  module CygUtils
    # Prefixed string
    #
    # @since 0.1.0
    class PathPrefix < Hanami::CygUtils::String
      # Path separator
      #
      # @since 0.3.1
      # @api private
      DEFAULT_SEPARATOR = "/"

      # Initialize the path prefix
      #
      # @param string [::String] the prefix value
      # @param separator [::String] the separator used between tokens
      #
      # @return [PathPrefix] self
      #
      # @since 0.1.0
      #
      # @see Hanami::CygUtils::PathPrefix::DEFAULT_SEPARATOR
      def initialize(string = nil, separator = DEFAULT_SEPARATOR)
        super(string)
        @separator = separator
      end

      # Joins self with the given token.
      # It cleans up all the `separator` repetitions.
      #
      # @param strings [::String] the token(s) we want to join
      #
      # @return [Hanami::CygUtils::PathPrefix] the joined string
      #
      # @since 0.1.0
      #
      # @example Single string
      #   require 'hanami/cyg_utils/path_prefix'
      #
      #   path_prefix = Hanami::CygUtils::PathPrefix.new('/posts')
      #   path_prefix.join('new').to_s  # => "/posts/new"
      #   path_prefix.join('/new').to_s # => "/posts/new"
      #
      #   path_prefix = Hanami::CygUtils::PathPrefix.new('posts')
      #   path_prefix.join('new').to_s  # => "/posts/new"
      #   path_prefix.join('/new').to_s # => "/posts/new"
      #
      # @example Multiple strings
      #   require 'hanami/cyg_utils/path_prefix'
      #
      #   path_prefix = Hanami::CygUtils::PathPrefix.new('myapp')
      #   path_prefix.join('/assets', 'application.js').to_s
      #     # => "/myapp/assets/application.js"
      def join(*strings)
        relative_join(strings).absolute!
      end

      # Joins self with the given token, without prefixing it with `separator`.
      # It cleans up all the `separator` repetitions.
      #
      # @param strings [::String] the tokens we want to join
      # @param separator [::String] the separator used between tokens
      #
      # @return [Hanami::CygUtils::PathPrefix] the joined string
      #
      # @raise [TypeError] if one of the argument can't be treated as a
      #   string
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/cyg_utils/path_prefix'
      #
      #   path_prefix = Hanami::CygUtils::PathPrefix.new 'posts'
      #   path_prefix.relative_join('new').to_s      # => 'posts/new'
      #   path_prefix.relative_join('new', '_').to_s # => 'posts_new'
      def relative_join(strings, separator = @separator)
        raise TypeError if separator.nil?

        prefix = @string.gsub(@separator, separator)
        result = [prefix, strings]
        result.flatten!
        result.compact!
        result.reject! { |string| string == separator }

        self.class.new(
          result.join(separator), separator
        ).relative!
      end

      protected

      # Modifies the path prefix to have a prepended separator.
      #
      # @return [self]
      #
      # @since 0.3.1
      # @api private
      #
      # @see #absolute
      def absolute!
        @string.prepend(separator) unless absolute?

        self
      end

      # Returns whether the path prefix starts with its separator.
      #
      # @return [TrueClass,FalseClass]
      #
      # @since 0.3.1
      # @api private
      #
      # @example
      #   require 'hanami/cyg_utils/path_prefix'
      #
      #   Hanami::CygUtils::PathPrefix.new('/posts').absolute? #=> true
      #   Hanami::CygUtils::PathPrefix.new('posts').absolute?  #=> false
      def absolute?
        @string.start_with?(separator)
      end

      # Modifies the path prefix to remove the leading separator.
      #
      # @return [self]
      #
      # @since 0.3.1
      # @api private
      #
      # @see #relative
      def relative!
        @string.gsub!(/(?<!:)#{separator * 2}/, separator)
        @string[/\A#{separator}|^/] = ""

        self
      end

      private

      # @since 0.1.0
      # @api private
      attr_reader :separator
    end
  end
end
