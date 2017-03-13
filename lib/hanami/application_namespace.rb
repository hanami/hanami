require 'hanami/utils/class'
require 'hanami/utils/string'

module Hanami
  # @api private
  class ApplicationNamespace
    # @api private
    def self.resolve(name)
      Utils::Class.load!(
        Utils::String.new(name).namespace
      )
    end
  end
end
