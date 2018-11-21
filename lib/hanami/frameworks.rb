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
    def mount(app, at:, host: nil, **args, &blk)
      super unless app.is_a?(Symbol)

      # TODO: this behavior should be centralized in a container
      namespace = Hanami::Utils::String.classify(app)
      namespace = Hanami::Utils::Class.load!("#{namespace}::Actions")
      configuration = Hanami::Controller::Configuration.new

      scope(at, namespace: namespace, configuration: configuration, &blk)
    end
  end
end
