require "delegate"

module Hanami
  # @api private
  class Configuration
    # @api private
    class App < SimpleDelegator
      # @api private
      attr_reader :path_prefix
      # @api private
      attr_reader :host

      # @api private
      def initialize(app, options = {})
        super(app)
        @path_prefix = options[:at]
        @host = options[:host]
      end
    end
  end
end
