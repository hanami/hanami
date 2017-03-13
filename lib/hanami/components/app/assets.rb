module Hanami
  # @since 0.9.0
  # @api private
  module Components
    # @since 0.9.0
    # @api private
    module App
      # hanami-assets configuration for a sigle Hanami application in the project.
      #
      # @since 0.9.0
      # @api private
      class Assets
        # Configure hanami-assets for a single Hanami application in the project.
        #
        # @param app [Hanami::Configuration::App] a Hanami application
        #
        # @since 0.9.0
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def self.resolve(app)
          config    = app.configuration
          namespace = app.namespace

          unless namespace.const_defined?('Assets', false)
            assets = Hanami::Assets.duplicate(namespace) do
              root             config.root

              scheme           config.scheme
              host             config.host
              port             config.port

              public_directory Hanami.public_directory
              prefix           Utils::PathPrefix.new('/assets').join(config.path_prefix)

              manifest         Hanami.public_directory.join('assets.json')
              compile          true

              config.assets.__apply(self)
            end

            assets.configure do
              cdn host != config.host
            end

            namespace.const_set('Assets', assets)
          end

          name = "#{app.app_name}.assets"
          Components.resolved(name, namespace.const_get('Assets').configuration)
          Components[name]
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
