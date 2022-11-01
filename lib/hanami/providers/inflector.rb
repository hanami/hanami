# frozen_string_literal: true

module Hanami
  # @api private
  module Providers
    # Provider source to register inflector component in Hanami slices.
    #
    # @api private
    # @since 2.0.0
    class Inflector < Dry::System::Provider::Source
      # @api private
      def start
        register :inflector, Hanami.app.inflector
      end
    end
  end
end
