require 'hanami/logger'

module Hanami
  module Components
    module App
      class Logger
        def self.resolve(app)
          config    = app.configuration
          namespace = app.namespace

          unless namespace.const_defined?('Logger', false)
            config.logger.app_name(namespace.to_s)
            namespace.const_set('Logger', config.logger.build)
          end
        end
      end
    end
  end
end
