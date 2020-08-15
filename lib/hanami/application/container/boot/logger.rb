Hanami.application.register_bootable :logger do
  start do
    require "hanami/logger"
    register :logger, Hanami::Logger.new(**Hanami.application.configuration.logger)
  end
end
