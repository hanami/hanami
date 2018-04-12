require "delegate"

module Hanami
  # @api private
  class Configuration
    # @api private
    class App < SimpleDelegator
      # @api private
      attr_reader :path_prefix

      # @api private
      def initialize(app, path_prefix)
        super(app)
        @path_prefix = path_prefix
      end
    end
  end
end
