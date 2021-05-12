# frozen_string_literal: true

Hanami.application.register_bootable :logger do
  start do
    register :logger, Hanami.application.configuration.logger.instance
  end
end
