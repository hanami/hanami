require 'hanami/cyg_utils/class'
require 'hanami/cyg_utils/string'

module Hanami
  # @api private
  class ApplicationNamespace
    # @api private
    def self.resolve(name)
      CygUtils::Class.load!(
        CygUtils::String.namespace(name)
      )
    end
  end
end
