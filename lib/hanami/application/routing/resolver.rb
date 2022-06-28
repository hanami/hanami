# frozen_string_literal: true

module Hanami
  class Application
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
        ENDPOINT_KEY_NAMESPACE = "actions"

        require_relative "resolver/trie"

        # @api private
        # @since 2.0.0
        def initialize(container:, slices:)
          @container = container
          @slices = slices
          @slice_registry = Trie.new
        end

        # @api private
        # @since 2.0.0
        #
        def call(path, identifier)
          endpoint =
            case identifier
            when String
              resolve_string_identifier(path, identifier)
            when Class
              identifier.respond_to?(:call) ? identifier : identifier.new
            else
              identifier
            end

          unless endpoint.respond_to?(:call)
            raise NotCallableEndpointError.new(endpoint)
          end

          endpoint
        end

        # @api private
        # @since 2.0.0
        def register_slice_at_path(name, path)
          slice_registry.add(path, name)
        end

        private

        # @api private
        # @since 2.0.0
        attr_reader :container

        # @api private
        # @since 2.0.0
        attr_reader :slices

        # @api private
        # @since 2.0.0
        attr_reader :slice_registry

        # @api private
        # @since 2.0.0
        def resolve_string_identifier(path, identifier)
          endpoint_key = "#{ENDPOINT_KEY_NAMESPACE}.#{identifier}"

          subject = if container.key?(endpoint_key)
                      container
                    elsif (slice_name = slice_registry.find(path))
                      slices[slice_name]
                    else
                      raise UnknownActionError.new(identifier)
                    end

          # TODO: make this implementation to work
          # subject = if container.key?(endpoint_key)
          #             container
          #           elsif (slice_name = slice_registry.find(path))
          #             slice = slices[slice_name]
          #             slice if slice.key?(endpoint_key) # <-------------- THIS LINE raises an exception sometimes
          #           end
          #
          # subject or raise UnknownActionError.new(identifier)

          # Lazily resolve endpoint from the slice to reduce router initialization time,
          # and break potential endless loops from the resolved endpoint itself requiring
          # access to router-related concerns
          -> (*args) { subject[endpoint_key].call(*args) }
        end
      end
    end
  end
end
