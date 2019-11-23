# frozen_string_literal: true

module Hanami
  class Application
    # Hanami application router endpoint resolver
    #
    # @since 2.0.0
    class EndpointResolver
      # @api private
      class NotCallableEndpointError < StandardError
        def initialize(endpoint)
          super("#{endpoint.inspect} isn't compatible with Rack. Please make sure it implements #call.")
        end
      end

      attr_reader :container
      attr_reader :base_namespace

      def initialize(container:, namespace:)
        @container = container
        @base_namespace = namespace
      end

      def with_container(new_container)
        self.class.new(
          container: new_container,
          namespace: base_namespace,
        )
      end

      # rubocop:disable Metrics/MethodLength
      def call(name, namespace = nil, configuration = nil)
        endpoint =
          case name
          when String
            resolve_string_identifier(name, namespace, configuration)
          when Class
            name.respond_to?(:call) ? name : name.new
          else
            name
          end

        unless endpoint.respond_to?(:call) # rubocop:disable Style/IfUnlessModifier
          raise NotCallableEndpointError.new(endpoint)
        end

        endpoint
      end
      # rubocop:enable Metrics/MethodLength

      private

      def resolve_string_identifier(name, namespace = nil, configuration = nil)
        identifier = [base_namespace, namespace, name].compact.join(".").tr("#", ".")

        endpoint = container[identifier]

        if configuration && endpoint.respond_to?(:with)
          endpoint.with(configuration: configuration)
        else
          endpoint
        end
      end
    end
  end
end
