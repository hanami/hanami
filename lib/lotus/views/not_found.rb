module Lotus
  module Views
    # The not found view that is rendered for 404 responses
    #
    # @since 0.1.0
    # @api private
    class NotFound < Base
      include Lotus::View
      configuration.reset!

      layout nil
      
      template '404'
      root(lib_root) unless customized_templates_exist?
    end
  end
end
