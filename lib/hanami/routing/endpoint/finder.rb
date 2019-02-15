# frozen_string_literal: true

require "hanami/routing/endpoint/resolver"

module Hanami
  module Routing
    module Endpoint
      # Find routing endpoints
      class Finder < Resolver
        def initialize(container: Hanami::Container)
          @container = container
          super()
        end

        def call(name, namespace, configuration = nil)
          action_for(name, namespace) ||
            super
        end

        private

        attr_reader :container

        def action_for(name, namespace)
          key = action_container_key(name, namespace)
          return unless container.key?(key)

          container[key]
        end

        # FIXME: extract this key pattern into a proper object
        def action_container_key(name, namespace)
          ["apps", namespace.name.downcase, name].join(".").gsub(/(::|#)/, ".")
        end
      end
    end
  end
end
