# frozen_string_literal: true

module Hanami
  module Web
    class EndpointResolver
      class NotCallableEndpointError < StandardError
        def initialize(endpoint)
          super("#{endpoint.inspect} isn't compatible with Rack. Please make sure it implements #call.")
        end
      end

      attr_reader :application
      attr_reader :container
      attr_reader :base_namespace

      def initialize(application:, container: application, namespace:)
        @application = application
        @container = container
        @base_namespace = namespace
      end

      def sliced(name)
        # TODO: formalize this
        raise "Slices can only be mounted from top-level application" unless application.respond_to?(:slices)

        slice = application.slices[name]
        return unless slice

        self.class.new(
          application: application,
          container: slice,
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
        identifier = [base_namespace, namespace, name].compact.join(".")

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
