# frozen_string_literal: true

module Hanami
  # Application routes
  #
  # Users are expected to inherit from this class to define their application
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
  #       define do
  #         root to: "home.show"
  #       end
  #     end
  #   end
  #
  #   See {Hanami::Slice::Router} for the syntax allowed within the
  #   `define` block.
  #
  # @see Hanami::Slice::Router
  # @since 2.0.0
  class Routes
    # Defines application routes
    #
    # @yield DSL syntax to define application routes executed in the context
    # of {Hanami::Slice::Router}
    #
    # @return [Proc]
    def self.define(&block)
      @_routes = block
    end

    # @api private
    def self.routes
      @_routes || raise(<<~MSG)
        Routes need to be defined before being able to fetch them. E.g.,
          define do
            slice :main, at: "/" do
              root to: "home.show"
            end
          end
      MSG
    end
  end
end
