# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Config
    # Hanami console config
    #
    # @since 2.3.0
    # @api public
    class Console
      include Dry::Configurable

      # @!attribute [rw] engine
      #  Sets or returns the interactive console engine to be used by `hanami console`.
      #  Supported values are `:irb` (default) and `:pry`.
      #
      #  @example
      #    config.console.engine = :pry
      #
      #  @return [Symbol]
      #
      #  @api public
      #  @since 2.3.0
      setting :engine, default: :irb

      # Returns the complete list of extensions to be used in the console
      #
      # @example
      #   config.console.include MyExtension, OtherExtension
      #   config.console.include ThirdExtension
      #
      #   config.console.extensions
      #   # => [MyExtension, OtherExtension, ThirdExtension]
      #
      # @return [Array<Module>]
      #
      # @api public
      # @since 2.3.0
      def extensions = @extensions.dup.freeze

      # Define a module extension to be included in the console
      #
      # @param mod [Module] one or more modules to be included in the console
      # @return [void]
      #
      # @api public
      # @since 2.3.0
      def include(*mod)
        @extensions.concat(mod).uniq!
      end

      # @api private
      def initialize
        @extensions = []
      end

      private

      # @api private
      def initialize_copy(source)
        super
        @extensions = [*source.extensions]
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
