require 'lotus/utils/class_attribute'
require 'lotus/frameworks'
require 'lotus/configuration'
require 'lotus/loader'
require 'lotus/rendering_policy'
require 'lotus/middleware'

module Lotus
  class Application
    include Lotus::Utils::ClassAttribute

    class_attribute :configuration
    self.configuration = Configuration.new

    def self.configure(&blk)
      configuration.configure(&blk)
    end

    attr_reader :routes

    # @api private
    attr_writer :routes

    def initialize
      @loader = Lotus::Loader.new(self)
      @loader.load!

      @rendering_policy = RenderingPolicy.new(configuration)
    end

    def configuration
      self.class.configuration
    end

    def call(env)
      middleware.call(env).tap do |response|
        @rendering_policy.render!(response)
      end
    end

    def middleware
      @middleware ||= Lotus::Middleware.new(self)
    end
  end
end
