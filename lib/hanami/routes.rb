# frozen_string_literal: true

require "hanami/slice/router"

module Hanami
  # App routes
  #
  # Users are expected to inherit from this class to define their app
  # routes.
  #
  # @example
  #   # config/routes.rb
  #   # frozen_string_literal: true
  #
  #   require "hanami/routes"
  #
  #   module MyApp
  #     class Routes < Hanami::Routes
  #       root to: "home.show"
  #     end
  #   end
  #
  #   See {Hanami::Slice::Router} for the syntax allowed within the `define` block.
  #
  # @see Hanami::Slice::Router
  # @since 2.0.0
  class Routes
    # @api private
    def self.routes
      @routes ||= build_routes
    end

    class << self
      # @api private
      def build_routes(definitions = self.definitions)
        return if definitions.empty?

        proc do
          definitions.each do |(name, args, kwargs, block)|
            if block
              public_send(name, *args, **kwargs, &block)
            else
              public_send(name, *args, **kwargs)
            end
          end
        end
      end

      # @api private
      def definitions
        @definitions ||= []
      end

      private

      # @api private
      def supported_methods
        @supported_methods ||= Slice::Router.public_instance_methods
      end

      # @api private
      def respond_to_missing?(name, include_private = false)
        supported_methods.include?(name) || super
      end

      # Capture all method calls that are supported by the router DSL
      # so that it can be evaluated lazily during configuration/boot
      # process
      #
      # @api private
      def method_missing(name, *args, **kwargs, &block)
        return super unless respond_to?(name)
        definitions << [name, args, kwargs, block]
        self
      end
    end
  end
end
