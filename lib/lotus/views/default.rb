module Lotus
  module Views
    # The default view that is rendered for non successful responses (200 and 201)
    #
    # @since 0.1.0
    # @api private
    class Default < Base
      include Lotus::View
      configuration.reset!

      layout nil

      template 'default'
      root lib_root
    end
  end
end
