module Hanami
  module Views
    # Null Object pattern for views
    #
    # @since 0.1.0
    # @api private
    class NullView
      # @since 0.1.0
      # @api private
      def render(_context)
        nil
      end
    end
  end
end
