require 'hanami/utils/path_prefix'

module Hanami
  module Components
    # Configurations for all the apps
    #
    # @since x.x.x
    class AppsAssetsConfigurations < Component
      register_as 'apps.assets.configurations'
      requires    'apps.configurations'

      def resolve
        result = []

        configuration.apps do |app, _|
          config = configuration_for(app)

          assets = Hanami::Assets::Configuration.new do
            root             config.root

            scheme           config.scheme
            host             config.host
            port             config.port

            public_directory Hanami.public_directory
            prefix           Utils::PathPrefix.new('/assets').join(config.path_prefix)

            manifest         Hanami.public_directory.join('assets.json')
            compile          true

            config.assets.__apply(self)
            cdn host != config.host
          end

          Components.resolved("#{app.app_name}.assets.configuration", assets)
          assets.load!

          result << assets
        end

        result
      end

      private

      def configuration_for(app)
        requirements["#{app.app_name}.configuration"]
      end
    end
  end
end
