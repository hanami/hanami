module Lotus
  module Routing
    class Default
      DEFAULT_CODE = 404
      DEFAULT_BODY = ['Not Found'].freeze

      def call(env)
        [ DEFAULT_CODE, {}, DEFAULT_BODY, nil ]
      end
    end
  end
end
