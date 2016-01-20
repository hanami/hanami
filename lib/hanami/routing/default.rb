module Hanami
  module Routing
    # The default Rack application that responds when a resource cannot be found.
    #
    # @since 0.1.0
    # @api private
    class Default
      DEFAULT_CODE = 404
      DEFAULT_BODY = ['Not Found'].freeze
      CONTENT_TYPE = 'Content-Type'.freeze

      class NullAction
        include Hanami::Action

        def call(env)
        end
      end

      def call(env)
        action = NullAction.new.tap { |a| a.call(env) }
        [ DEFAULT_CODE, {CONTENT_TYPE => action.content_type}, DEFAULT_BODY, action ]
      end
    end
  end
end
