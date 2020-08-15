Hanami.application.register_bootable :rack_logger do |container|
  start do
    require "hanami/web/rack_logger"

    use :logger
    use :rack_monitor

    rack_logger = Hanami::Web::RackLogger.new(
      container[:logger],
      filter_params: Hanami.application.configuration.rack_logger_filter_params
    )

    rack_logger.attach container[:rack_monitor]

    register :rack_logger, rack_logger
  end
end
