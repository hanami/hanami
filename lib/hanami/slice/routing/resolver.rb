# frozen_string_literal: true

require_relative "../../routes"

module Hanami
  class Slice
    # @api private
    module Routing
      # Hanami app router endpoint resolver
      #
      # This resolves endpoints objects from a slice container using the strings passed to `to:` as
      # their container keys.
      #
      # @api private
      # @since 2.0.0
      class Resolver
        # @api private
        # @since 2.0.0
        def initialize(slice:)
          @slice = slice
        end

        # @api private
        # @since 2.0.0
        def find_slice(slice_name)
          slice.slices[slice_name]
        end

        # @api private
        # @since 2.0.0
        def to_slice(slice_name)
          self.class.new(slice: find_slice(slice_name))
        end

        # @api private
        # @since 2.0.0
        def call(_path, endpoint)
          endpoint =
            case endpoint
            when String
              Endpoint.new(endpoint, slice)
            when Class
              endpoint.respond_to?(:call) ? endpoint : endpoint.new
            else
              endpoint
            end

          unless endpoint.respond_to?(:call)
            raise Routes::NotCallableEndpointError.new(endpoint)
          end

          endpoint
        end

        private

        # @api private
        # @since 2.0.0
        attr_reader :slice
      end
    end
  end
end
