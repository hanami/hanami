require 'lotus/utils/class_attribute'
require 'lotus/configuration'

module Lotus
  class Application
    include Lotus::Utils::ClassAttribute
    class_attribute :configuration

    def self.configure(&blk)
      self.configuration = Configuration.new(&blk)
    end
  end
end
