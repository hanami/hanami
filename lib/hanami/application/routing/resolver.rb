# frozen_string_literal: true

module Hanami
  class Application
    module Routing
      # Hanami application router endpoint resolver
      #
      # @since 2.0.0
      class Resolver
        require_relative "resolver/trie"

        # @api private
        class NotCallableEndpointError < StandardError
          def initialize(endpoint)
            super("#{endpoint.inspect} is not compatible with Rack. Please make sure it implements #call.")
          end
        end

        def initialize(slices:, inflector:)
          @slices = slices
          @inflector = inflector
          @slices_registry = Trie.new
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

        def register_slice_at_path(name, path)
          slices_registry.add(path, name)
        end

        private

        attr_reader :slices
        attr_reader :inflector
        attr_reader :slices_registry

        def resolve_string_identifier(path, identifier)
          slice_name = slices_registry.find(path) or raise "missing slice for #{path.inspect} (#{identifier.inspect})"
          slice = slices[slice_name]
          action_key = "actions.#{identifier.gsub(/[#\/]/, '.')}"

          slice[action_key]
        end
      end
    end
  end
end
