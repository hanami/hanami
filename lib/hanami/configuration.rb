require 'concurrent'

module Hanami
  class Configuration
    def initialize(&blk)
      @settings = Concurrent::Map.new
      instance_eval(&blk)
    end

    def mount(app, options)
      apps[app] = options.fetch(:at)
    end

    def model(&blk)
      settings.put_if_absent(:model, blk)
    end

    def mailer(&blk)
      settings.put_if_absent(:mailer, blk)
    end

    def apps
      settings.fetch_or_store(:apps, {})
    end

    private

    attr_reader :settings
  end
end
