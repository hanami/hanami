module Lotus
  module Views
    # The unprocessable entity view that is rendered for 422 responses
    #
    # @since 0.1.0
    # @api private
    class UnprocessableEntity < Base
      include Lotus::View
      configuration.reset!

      layout nil
      
      template '422'
      root(lib_root) unless customized_templates_exist?
    end
  end
end
