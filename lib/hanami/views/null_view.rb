module Hanami
  module Views
    # Null Object pattern for views
    #
    # @since 0.1.0
    # @api private
    class NullView
      def initialize(body)
        @body = body
      end

      def render(_context)
        @body
      end
    end
  end
end
