module Hanami
  module Components
    # Configurations for all the apps
    #
    # @since x.x.x
    class AppsConfigurations < Component
      register_as 'apps.configurations'

      def resolve
        configuration.apps do |app, path_prefix|
          config = app.configuration
          config.path_prefix path_prefix
          config.load!(app.app_name)

          Components.resolved("#{app.app_name}.configuration", config)
        end

        true
      end
    end
  end
end
