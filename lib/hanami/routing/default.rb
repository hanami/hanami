module Hanami
  # @api private
  module Routing
    # The default Rack application that responds when a resource cannot be found.
    #
    # @since 0.1.0
    # @api private
    class Default
      # @api private
      DEFAULT_CODE = 404
      # @api private
      DEFAULT_BODY = ['Not Found'].freeze
      # @api private
      CONTENT_TYPE = 'Content-Type'.freeze

      # @api private
      class NullAction
        include Hanami::Action

        # @api private
        def call(env)
        end
      end

      # @api private
      def call(env)
        action = NullAction.new.tap { |a| a.call(env) }
        [ DEFAULT_CODE, {CONTENT_TYPE => action.content_type}, DEFAULT_BODY, action ]
      end
    end
  end
end
