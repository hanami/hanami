require 'lotus/utils/class_attribute'
require 'lotus/frameworks'
require 'lotus/configuration'
require 'lotus/loader'

module Lotus
  class Application
    include Lotus::Utils::ClassAttribute
    class_attribute :configuration

    def self.configure(&blk)
      self.configuration = Configuration.new(&blk)
    end

    attr_accessor :routes#, :mapping

    def initialize
      @loader = Lotus::Loader.new(self)
      @loader.load!
    end

    def configuration
      self.class.configuration
    end

    def call(env)
      # FIXME don't assume that "Controllers" will be always part of the class name
      @routes.call(env).tap do |response|
        action = response.pop
        view   = Utils::Class.load!(action.class.name.gsub('Controllers', 'Views'))

        # FIXME consider only "renderable" statuses
        # FIXME handle non-successful statuses with Lotus views such as Lotus::Views::ServerErrorView
        response[2] = Array(view.render(action.exposures.merge(format: :html)))
      end
    end
  end
end
