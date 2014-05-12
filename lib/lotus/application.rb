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

    attr_accessor :routes, :mapping

    def initialize
      @loader = Lotus::Loader.new(self)
      @loader.load!
    end

    def configuration
      self.class.configuration
    end
  end
end
