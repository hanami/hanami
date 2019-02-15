# frozen_string_literal: true

require "hanami/utils"
require "hanami/router"
require "hanami/controller"
require "hanami/utils/string"
require "hanami/utils/class"

# Hanami
#
# @since 0.1.0
module Hanami
  # Hanami::Router enhancements
  #
  # @since 2.0.0
  class Router
    # rubocop:disable Metrics/ParameterLists
    def mount(app, at:, host: nil, container: Hanami::Container, **args, &blk)
      super(app, at: at, host: host, **args, &blk) unless app.is_a?(Symbol)

      # FIXME: extract this key pattern into a proper object
      namespace = container["apps.#{app}.actions.namespace"]
      scope(at, namespace: namespace, configuration: nil, &blk)
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
