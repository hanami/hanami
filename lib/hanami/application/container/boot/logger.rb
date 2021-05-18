# frozen_string_literal: true

Hanami.application.register_bootable :logger do
  start do
    logger_config = Hanami.application.configuration.logger

    logger =
      if (logger_instance = logger_config.instance)
        logger_instance
      else
        logger_config.logger_class.new(**logger_config.options)
      end

    register :logger, logger
  end
end
