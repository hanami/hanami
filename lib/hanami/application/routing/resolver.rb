# frozen_string_literal: true

module Hanami
  class Application
    module Routing
      # Hanami application router endpoint resolver
      #
      # @since 2.0.0
      class Resolver
        require_relative "resolver/trie"

        # @since 2.0.0
        class NotCallableEndpointError < StandardError
          def initialize(endpoint)
            super("#{endpoint.inspect} is not compatible with Rack. Please make sure it implements #call.")
          end
        end

        # @api private
        # @since 2.0.0
        def initialize(slices:, inflector:)
          @slices = slices
          @inflector = inflector
          @slices_registry = Trie.new
        end

        # @api private
        # @since 2.0.0
        #
        # rubocop:disable Metrics/MethodLength
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

          unless endpoint.respond_to?(:call) # rubocop:disable Style/IfUnlessModifier
            raise NotCallableEndpointError.new(endpoint)
          end

          endpoint
        end
        # rubocop:enable Metrics/MethodLength

        # @api private
        # @since 2.0.0
        def register_slice_at_path(name, path)
          slices_registry.add(path, name)
        end

        private

        # @api private
        # @since 2.0.0
        attr_reader :slices

        # @api private
        # @since 2.0.0
        attr_reader :inflector

        # @api private
        # @since 2.0.0
        attr_reader :slices_registry

        # @api private
        # @since 2.0.0
        def resolve_string_identifier(path, identifier)
          slice_name = slices_registry.find(path) or raise "missing slice for #{path.inspect} (#{identifier.inspect})"
          slice = slices[slice_name]
          action_key = "actions.#{identifier}"

          slice[action_key]
        end
      end
    end
  end
end
