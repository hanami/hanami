# frozen_string_literal: true

# require_relative "plugins/relation_readers"
require_relative "plugins/slice_readers"

module Hanami
  module Console
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
