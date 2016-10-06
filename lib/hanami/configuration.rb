require 'concurrent'
require 'hanami/application'

module Hanami
  class Configuration
    def initialize(&blk)
      @settings = Concurrent::Map.new
      instance_eval(&blk)
    end

    def mount(app, options)
      mounted[app] = options.fetch(:at)
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
      mounted.each_pair do |app, path_prefix|
        yield(app, path_prefix) if app.ancestors.include?(Hanami::Application)
      end
    end

    private

    attr_reader :settings
  end
end
