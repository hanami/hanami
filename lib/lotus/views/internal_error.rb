module Lotus
  module Views
    # The internal error view that is rendered for 500 responses
    #
    # @since 0.1.0
    # @api private
    class InternalError < Base
      include Lotus::View
      configuration.reset!

      layout nil

      template '500'
      root(lib_root) unless customized_templates_exist?
    end
  end
end
