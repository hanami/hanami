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
      attr_reader :inflector
      attr_reader :slices

      def initialize(container:, namespace:, inflector:, slices: {})
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

      def register_slice(path, identifier)
        slices[path] = identifier
      end

      private

      # rubocop:disable Metrics/AbcSize
      def resolve_string_identifier(path, identifier)
        # TODO: verify if we want a `:default` slice, instead of `:web` (from Hanami 1).
        slice = slices.find { |prefix, _| path.start_with?(prefix) }&.last || :default
        namespace = container.slices.fetch(slice).namespace
        class_name = identifier.split(/[#\/]/).map { |token| inflector.classify(token) }.join("::")
        endpoint = inflector.constantize("#{namespace}::Actions::#{class_name}")

        # FIXME: slice must return this configuration, according to the app settings
        configuration = Hanami::Controller::Configuration.new
        endpoint.new(configuration: configuration)
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
