# frozen_string_literal: true

Hanami.application.register_bootable :logger do
  start do
    register :logger, Hanami.application.configuration.logger_instance
  end
end
