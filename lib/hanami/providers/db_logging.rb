# frozen_string_literal: true

module Hanami
  module Providers
    # @api private
    # @since 2.2.0
    class DBLogging < Hanami::Provider::Source
      # @api private
      # @since 2.2.0
      def prepare
        require "dry/monitor/sql/logger"
        slice["notifications"].register_event :sql
      end

      # @api private
      # @since 2.2.0
      def start
        Dry::Monitor::SQL::Logger.new(slice["logger"]).subscribe(slice["notifications"])
      end
    end
  end
end
