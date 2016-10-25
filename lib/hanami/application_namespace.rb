require 'hanami/utils/class'
require 'hanami/utils/string'

module Hanami
  class ApplicationNamespace
    def self.resolve(name)
      Utils::Class.load!(
        Utils::String.new(name).namespace
      )
    end
  end
end
