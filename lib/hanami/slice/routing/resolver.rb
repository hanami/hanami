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
        SLICE_ACTIONS_KEY_NAMESPACE = "actions"

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
              resolve_slice_action(endpoint)
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

        # @api private
        # @since 2.0.0
        def resolve_slice_action(key)
          action_key = "#{SLICE_ACTIONS_KEY_NAMESPACE}.#{key}"

          ensure_action_in_slice(action_key)

          # Lazily resolve action from the slice to reduce router initialization time, and
          # circumvent endless loops from the action requiring access to router-related
          # concerns (which may not be fully loaded at the time of reading the routes)
          -> (*args) {
            action = slice.resolve(action_key) do
              raise Routes::MissingActionError.new(action_key, slice)
            end

            action.call(*args)
          }
        end

        def ensure_action_in_slice(key)
          return unless slice.booted?

          raise Routes::MissingActionError.new(key, slice) unless slice.key?(key)
        end
      end
    end
  end
end
