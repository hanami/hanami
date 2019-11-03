# frozen_string_literal: true

module Hanami
  module Web
    class EndpointResolver
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

        unless endpoint.respond_to?(:call)
          raise NotCallableEndpointError.new(endpoint)
        end

        endpoint
      end

      private

      def resolve_string_identifier(name, namespace, configuration)
        identifier = [base_namespace, namespace, name].compact.join(".").gsub("#", ".")

        container[identifier].yield_self { |endpoint|
          if configuration && endpoint.class < Hanami::Action
            endpoint.with(configuration: configuration)
          else
            endpoint
          end
        }
      end
    end
  end
end
