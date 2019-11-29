# frozen_string_literal: true

require_relative "plugins/slice_readers"

module Hanami
  module Console
    # Hanami application console context
    #
    # @api private
    # @since 2.0.0
    class Context < SimpleDelegator
      attr_reader :application

      def self.new(*args)
        ctx = super

        ctx.extend(Plugins::SliceReaders.new(ctx))

        ctx
      end

      def initialize(application)
        super(application)
        @application = application
      end
    end
  end
end
