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

    def self.configure(&blk)
      self.configuration = Configuration.new(&blk)
    end

    attr_reader :routes

    # @api private
    attr_writer :routes

    def initialize(rendering_policy = RenderingPolicy.new)
      @rendering_policy = rendering_policy

      @loader = Lotus::Loader.new(self)
      @loader.load!
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
