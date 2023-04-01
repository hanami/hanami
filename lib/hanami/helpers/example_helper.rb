# frozen_string_literal: true

module Hanami
  module Helpers
    # This is a temporary example helper module to demonstrate built-in helper integration.
    #
    # This will be removed when Hanami's proper first-party helpers are introduced.
    #
    # @api private
    module ExampleHelper
      module_function

      # @api private
      def exclaim(str)
        "#{str}!"
      end
    end
  end
end
