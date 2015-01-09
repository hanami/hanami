require 'logger'
require 'lotus/utils/string'

module Lotus
  # Lotus default logger
  #
  # Implement with the same interface of ruby std ::Logger
  # Opts out the logdev parameter and always use STDOUT as outout device
  #
  # Lotus logger also has the app tag concept, which used to identify
  # which application the log come from.
  #
  # Lotus Logger default comes with Lotus application
  # and uses name of highest module namespace as app_tag
  #
  # When stands alone, Lotus Logger tries to infer app tag from highest namespace
  # When has no namespace, Lotus Logger takes [Shared] as default app tag
  #
  # @example
  #   #1 Logger with namespace
  #   module TestApp
  #     class AppLogger << Lotus::Logger; end
  #     def log
  #       Applogger.new.info('foo')
  #       #=> output: I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [TestApp] : foo
  #     end
  #   end
  #
  #   #2 Logger without namespace
  #   class AppLogger < Lotus::Logger
  #   end
  #   Applogger.new.info('foo')
  #   #=> output: I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [Shared] : foo
  #
  #   #3 Logger inside a lotus application
  #   module LotusModule
  #     class App < Lotus::Application
  #       load!
  #     end
  #   end
  #   LotusModule::Logger.info('foo')
  #   => output: I, [2015-01-10T21:55:12.727259 #80487]  INFO -- [LotusModule] : foo
  #
  # @see ::Logger
  #
  # @since 0.2.1
  class Logger < ::Logger

    attr_accessor :app_tag

    # Override Ruby's Logger#initialize
    #
    # @param logdev is default to STDOUT
    #
    # @since 0.2.1
    def initialize(app_tag=nil, *args)
      super(STDOUT, *args)
      @app_tag = app_tag
      @formatter = Lotus::Logger::Formatter.new.tap { |f| f.app_tag = self.app_tag }
    end

    # app_tag is the identification of current app
    # app_tag is default to use highest namespace if current namespace
    # if app_tag is blank, lotus use default app_tag 'shared'
    # @param logdev is default to STDOUT
    #
    # @since 0.2.1
    def app_tag
      @app_tag || _app_tag_from_namespace || _default_app_tag
    end

    class Formatter < ::Logger::Formatter
      attr_accessor :app_tag

      def call(severity, time, progname, msg)
        time = time.utc
        progname = "[#{@app_tag}] #{progname}"
        super(severity, time, progname, msg)
      end
    end

    private
    def _app_tag_from_namespace
      class_name = self.class.name
      return nil unless class_name.index('::')

      Utils::String.new(class_name).namespace
    end

    def _default_app_tag
      'Shared'
    end
  end
end
