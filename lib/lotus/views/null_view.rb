module Lotus
  module Views
    class NullView
      def initialize(body)
        @body = body
      end

      def render(context)
        @body
      end
    end
  end
end
