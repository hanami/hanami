# frozen_string_literal: true

module Hanami
  class Application
    module Routing
      # Hanami application router endpoint resolver
      #
      # @since 2.0.0
      class Resolver
        require "hanami/application/routing/resolver/trie"

        # @api private
        class NotCallableEndpointError < StandardError
          def initialize(endpoint)
            super("#{endpoint.inspect} isn't compatible with Rack. Please make sure it implements #call.")
          end
        end

        attr_reader :container
        attr_reader :base_namespace
        attr_reader :inflector
        attr_reader :slices

        def initialize(container:, namespace:, inflector:, slices: Trie.new)
          @container = container
          @base_namespace = namespace
          @inflector = inflector
          @slices = slices
        end

        def with_container(new_container)
          self.class.new(
            container: new_container,
            namespace: base_namespace,
          )
        end

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

        def register_slice(path, name)
          slices.add(path, name)
        end

        private

        def resolve_string_identifier(path, identifier)
          slice_name = slices.find(path) or raise "missing slice for #{path.inspect} (#{identifier.inspect})"
          slice = container.slices[slice_name]
          action_key = "actions.#{identifier.gsub(/[#\/]/, '.')}"

          slice[action_key]
        end
      end
    end
  end
end
