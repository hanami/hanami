# frozen_string_literal: true

require_relative "constants"
require_relative "errors"

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
    # Error raised when no action could be found in an app or slice container for the key given in a
    # routes file.
    #
    # @api public
    # @since 2.0.0
    class MissingActionError < Hanami::Error
      # @api private
      def initialize(action_key, slice)
        action_path = action_key.gsub(CONTAINER_KEY_DELIMITER, PATH_DELIMITER)
        action_constant = slice.inflector.camelize(
          "#{slice.inflector.underscore(slice.namespace.to_s)}#{PATH_DELIMITER}#{action_path}"
        )
        action_file = slice.root.join("#{action_path}#{RB_EXT}")

        super(<<~MSG)
          Could not find action with key #{action_key.inspect} in #{slice}

          To fix this, define the action class #{action_constant} in #{action_file}
        MSG
      end
    end

    # Error raised when a given routes endpoint does not implement the `#call` interface required
    # for Rack.
    #
    # @api public
    # @since 2.0.0
    class NotCallableEndpointError < Hanami::Error
      # @api private
      def initialize(endpoint)
        super("#{endpoint.inspect} is not compatible with Rack. Please make sure it implements #call.")
      end
    end

    # Wrapper class for the (otherwise opaque) proc returned from {.routes}, adding an `#empty?`
    # method that returns true if no routes were defined.
    #
    # This is useful when needing to determine behaviour based on the presence of user-defined
    # routes, such as determining whether to show the Hanami welcome page in {Slice#load_router}.
    #
    # @api private
    # @since 2.1.0
    class RoutesProc < DelegateClass(Proc)
      # @api private
      # @since 2.1.0
      def self.empty
        new(proc {}, empty: true)
      end

      # @api private
      # @since 2.1.0
      def initialize(proc, empty: false)
        @empty = empty
        super(proc)
      end

      # @api private
      # @since 2.1.0
      def empty?
        !!@empty
      end
    end

    # @api private
    def self.routes
      @routes ||= build_routes
    end

    class << self
      # @api private
      def build_routes(definitions = self.definitions)
        return RoutesProc.empty if definitions.empty?

        routes_proc = proc do
          definitions.each do |(name, args, kwargs, block)|
            if block
              public_send(name, *args, **kwargs, &block)
            else
              public_send(name, *args, **kwargs)
            end
          end
        end

        RoutesProc.new(routes_proc)
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
