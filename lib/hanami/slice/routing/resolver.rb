# frozen_string_literal: true

module Hanami
  class Slice
    module Routing
      # @since 2.0.0
      class UnknownActionError < Hanami::Error
        def initialize(identifier)
          super("unknown action referenced in router: `#{identifier.inspect}'")
        end
      end

      # @since 2.0.0
      class NotCallableEndpointError < StandardError
        def initialize(endpoint)
          super("#{endpoint.inspect} is not compatible with Rack. Please make sure it implements #call.")
        end
      end

      # Hanami application router endpoint resolver
      #
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
        def to_slice(slice_name)
          self.class.new(slice: slice.slices[slice_name])
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
            raise NotCallableEndpointError.new(endpoint)
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
              raise UnknownActionError.new(key)
            end

            action.call(*args)
          }
        end

        def ensure_action_in_slice(key)
          return unless slice.booted?

          raise UnknownActionError.new(key) unless slice.key?(key)
        end
      end
    end
  end
end
