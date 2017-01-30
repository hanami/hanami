require 'concurrent'
require 'delegate'
require 'hanami/application'
require 'hanami/utils/class'
require 'hanami/utils/string'

module Hanami
  class Configuration
    class App < SimpleDelegator
      attr_reader :path_prefix

      def initialize(app, path_prefix)
        super(app)
        @path_prefix = path_prefix
      end
    end

    def initialize(&blk)
      @settings = Concurrent::Map.new
      instance_eval(&blk)
    end

    def mount(app, options)
      mounted[app] = App.new(app, options.fetch(:at))
    end

    def model(&blk)
      if block_given?
        settings.put_if_absent(:model, blk)
      else
        settings.fetch(:model)
      end
    end

    def mailer(&blk)
      settings.put_if_absent(:mailer, blk)
    end

    def mounted
      settings.fetch_or_store(:mounted, {})
    end

    def apps
      mounted.each_pair do |klass, app|
        yield(app) if klass.ancestors.include?(Hanami::Application)
      end
    end

    def logger(options = nil)
      if options.nil?
        settings.fetch(:logger)
      else
        settings.put_if_absent(:logger, options)
      end
    end

    private

    attr_reader :settings
  end
end
