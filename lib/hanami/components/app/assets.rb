module Hanami
  module Components
    module App
      class Assets
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
        end
      end
    end
  end
end
