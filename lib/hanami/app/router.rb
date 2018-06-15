require "hanami/router"
require "hanami/action/response"
require "hanami/application"
require "hanami/components"
require "hanami/utils/string"
require "hanami/utils/class"

module Hanami
  class App
    class Router < Hanami::Router
      # @param configuration [Hanami::Configuration] general configuration
      def initialize(configuration)
        super(inflector: configuration.inflector) do
          configuration.mounted.each do |klass, app|
            if klass.ancestors.include?(Hanami::Application)
              namespace = Utils::String.namespace(klass.name)
              namespace = Utils::Class.load!("#{namespace}::Controllers")
              controller_configuration = Components["#{app.app_name}.controller"]
              scope(app.path_prefix, namespace: namespace, configuration: controller_configuration, &klass.configuration.routes)
            else
              mount(klass, at: app.path_prefix)
            end
          end
        end
      end

      def call(env)
        _wrap(env, super)
      end

      private

      def _wrap(env, response)
        case response
        when Hanami::Action::Response
          response
        else
          Hanami::Action::Response.build(response, env)
        end
      end
    end
  end
end
